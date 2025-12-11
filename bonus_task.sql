--Nuray Mukhambet. 24B031895

--creating databases
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('active', 'blocked', 'frozen')) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15, 2) DEFAULT 10000000.00
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number VARCHAR(34) UNIQUE NOT NULL,
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')) NOT NULL,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(15, 8) NOT NULL,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP NULL,
    UNIQUE (from_currency, to_currency, valid_from)
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INTEGER REFERENCES accounts(account_id) ON DELETE SET NULL,
    to_account_id INTEGER REFERENCES accounts(account_id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(15, 8) DEFAULT 1.00,
    amount_kzt DECIMAL(15, 2) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    description TEXT
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45)
);

--populating them
INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('120345678901', 'Aibek Nurmaganbet', '+7(701)1234567', 'aibek@bank.kz', 'active', 100000000.00),
('120345678902', 'Zhanibek Salamov', '+7(702)1234568', 'zhanibek@bank.kz', 'active', 20000000.00),
('120345678903', 'Gulnara Bekbayeva', '+7(703)1234569', 'gulnara@bank.kz', 'active', 10000000.00),
('120345678904', 'Dmitry Petrov', '+7(704)1234570', 'dmitry@bank.kz', 'blocked', 5000000.00),
('120345678905', 'Maria Smirnova', '+7(705)1234571', 'maria@bank.kz', 'frozen', 8000000.00),
('120345678906', 'Kairat Ismailov', '+7(706)1234572', 'kairat@bank.kz', 'active', 12000000.00),
('120345678907', 'Aliya Tashkenbayeva', '+7(707)1234573', 'aliya@bank.kz', 'active', 18000000.00),
('120345678908', 'Sergey Volkov', '+7(708)1234574', 'sergey@bank.kz', 'active', 11000000.00),
('120345678909', 'Nazym Adilbekova', '+7(709)1234575', 'nazym@bank.kz', 'active', 9000000.00),
('120345678910', 'Ramazan Japarov', '+7(710)1234576', 'ramazan@bank.kz', 'active', 22000000.00);

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_to) VALUES
('KZT', 'USD', 0.0021, CURRENT_TIMESTAMP, NULL),
('USD', 'KZT', 476.19, CURRENT_TIMESTAMP, NULL),
('KZT', 'EUR', 0.0019, CURRENT_TIMESTAMP, NULL),
('EUR', 'KZT', 526.32, CURRENT_TIMESTAMP, NULL),
('KZT', 'RUB', 0.041, CURRENT_TIMESTAMP, NULL),
('RUB', 'KZT', 24.39, CURRENT_TIMESTAMP, NULL),
('USD', 'EUR', 0.92, CURRENT_TIMESTAMP, NULL),
('EUR', 'USD', 1.09, CURRENT_TIMESTAMP, NULL);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
(1, 'KZ86010250000001000000', 'KZT', 50000000.00, TRUE),
(1, 'KZ86010250000001000001', 'USD', 150000.00, TRUE),
(2, 'KZ86010250000002000000', 'KZT', 100000000.00, TRUE),
(2, 'KZ86010250000002000001', 'EUR', 200000.00, TRUE),
(3, 'KZ86010250000003000000', 'KZT', 35000000.00, TRUE),
(4, 'KZ86010250000004000000', 'KZT', 5000000.00, FALSE),
(5, 'KZ86010250000005000000', 'KZT', 8000000.00, TRUE),
(6, 'KZ86010250000006000000', 'KZT', 75000000.00, TRUE),
(7, 'KZ86010250000007000000', 'USD', 300000.00, TRUE),
(8, 'KZ86010250000008000000', 'RUB', 5000000.00, TRUE);

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description) VALUES
(1, 3, 1000000.00, 'KZT', 1.00, 1000000.00, 'transfer', 'completed', 'Initial transfer test'),
(2, 1, 500000.00, 'EUR', 526.32, 263160000.00, 'transfer', 'completed', 'EUR to KZT transfer'),
(6, 5, 2000000.00, 'KZT', 1.00, 2000000.00, 'transfer', 'completed', 'Payment test'),
(1, 7, 100000.00, 'USD', 476.19, 47619000.00, 'transfer', 'completed', 'Cross-currency transfer');

--task 1
CREATE OR REPLACE FUNCTION process_transfer(
    p_from_account_number VARCHAR,
    p_to_account_number VARCHAR,
    p_amount DECIMAL,
    p_currency VARCHAR,
    p_description TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    out_transaction_id INTEGER,
    error_code VARCHAR,
    error_message TEXT,
    final_from_balance DECIMAL,
    final_to_balance DECIMAL
) AS $$
DECLARE
    v_from_account_id INTEGER;
    v_to_account_id INTEGER;
    v_from_customer_id INTEGER;
    v_to_customer_id INTEGER;
    v_from_balance DECIMAL;
    v_to_balance DECIMAL;
    v_from_currency VARCHAR;
    v_to_currency VARCHAR;
    v_from_customer_status VARCHAR;
    v_exchange_rate DECIMAL;
    v_amount_kzt DECIMAL;
    v_transaction_id INTEGER;
    v_today_total_kzt DECIMAL;
    v_new_transaction_id INTEGER;
    v_error_code VARCHAR;
    v_error_msg TEXT;
BEGIN
    v_error_code := NULL;
    v_error_msg := NULL;
    v_transaction_id := NULL;

    BEGIN
        SELECT a.account_id, a.customer_id, a.balance, a.currency, c.status
        INTO v_from_account_id, v_from_customer_id, v_from_balance, v_from_currency, v_from_customer_status
        FROM accounts a
        JOIN customers c ON a.customer_id = c.customer_id
        WHERE a.account_number = p_from_account_number AND a.is_active = TRUE
        FOR UPDATE;

        IF v_from_account_id IS NULL THEN
            v_error_code := 'ERR_FROM_ACCOUNT_NOT_FOUND';
            v_error_msg := 'Source account not found or is inactive';
            RAISE EXCEPTION '%', v_error_msg;
        END IF;

        IF v_from_customer_status != 'active' THEN
            v_error_code := 'ERR_CUSTOMER_NOT_ACTIVE';
            v_error_msg := 'Customer status is ' || v_from_customer_status;
            RAISE EXCEPTION '%', v_error_msg;
        END IF;

        SELECT a.account_id, a.customer_id, a.balance, a.currency
        INTO v_to_account_id, v_to_customer_id, v_to_balance, v_to_currency
        FROM accounts a
        WHERE a.account_number = p_to_account_number AND a.is_active = TRUE
        FOR UPDATE;

        IF v_to_account_id IS NULL THEN
            v_error_code := 'ERR_TO_ACCOUNT_NOT_FOUND';
            v_error_msg := 'Destination account not found or is inactive';
            RAISE EXCEPTION '%', v_error_msg;
        END IF;

        IF v_from_currency = 'KZT' THEN
            v_exchange_rate := 1.00;
            v_amount_kzt := p_amount;
        ELSE
            SELECT rate INTO v_exchange_rate
            FROM exchange_rates
            WHERE from_currency = v_from_currency AND to_currency = 'KZT'
              AND valid_from <= CURRENT_TIMESTAMP
              AND (valid_to IS NULL OR valid_to >= CURRENT_TIMESTAMP)
            ORDER BY valid_from DESC
            LIMIT 1;

            IF v_exchange_rate IS NULL THEN
                v_error_code := 'ERR_EXCHANGE_RATE_NOT_FOUND';
                v_error_msg := 'Exchange rate not available for ' || v_from_currency;
                RAISE EXCEPTION '%', v_error_msg;
            END IF;

            v_amount_kzt := p_amount * v_exchange_rate;
        END IF;

        IF v_from_balance < p_amount THEN
            v_error_code := 'ERR_INSUFFICIENT_BALANCE';
            v_error_msg := 'Insufficient balance. Available: ' || v_from_balance;
            RAISE EXCEPTION '%', v_error_msg;
        END IF;

        SELECT COALESCE(SUM(amount_kzt), 0)
        INTO v_today_total_kzt
        FROM transactions
        WHERE from_account_id = v_from_account_id
          AND DATE(created_at) = CURRENT_DATE
          AND status IN ('completed', 'pending');

        IF (v_today_total_kzt + v_amount_kzt) > (
            SELECT daily_limit_kzt FROM customers WHERE customer_id = v_from_customer_id
        ) THEN
            v_error_code := 'ERR_DAILY_LIMIT_EXCEEDED';
            v_error_msg := 'Daily transaction limit exceeded. Today total: ' || v_today_total_kzt || ' + ' || v_amount_kzt;
            RAISE EXCEPTION '%', v_error_msg;
        END IF;

        INSERT INTO transactions (
            from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt,
            type, status, description, created_at
        ) VALUES (
            v_from_account_id, v_to_account_id, p_amount, p_currency, v_exchange_rate, v_amount_kzt,
            'transfer', 'completed', p_description, CURRENT_TIMESTAMP
        )
        RETURNING transaction_id INTO v_new_transaction_id;

        UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from_account_id;

        IF v_to_currency != p_currency THEN
            SELECT rate INTO v_exchange_rate
            FROM exchange_rates
            WHERE from_currency = p_currency AND to_currency = v_to_currency
              AND valid_from <= CURRENT_TIMESTAMP
              AND (valid_to IS NULL OR valid_to >= CURRENT_TIMESTAMP)
            ORDER BY valid_from DESC
            LIMIT 1;

            IF v_exchange_rate IS NULL THEN
                v_error_code := 'ERR_CONVERSION_RATE_NOT_FOUND';
                v_error_msg := 'Cannot convert ' || p_currency || ' to ' || v_to_currency;
                RAISE EXCEPTION '%', v_error_msg;
            END IF;

            UPDATE accounts SET balance = balance + (p_amount * v_exchange_rate) WHERE account_id = v_to_account_id;
        ELSE
            UPDATE accounts SET balance = balance + p_amount WHERE account_id = v_to_account_id;
        END IF;

        UPDATE transactions SET completed_at = CURRENT_TIMESTAMP WHERE transactions.transaction_id = v_new_transaction_id;

        SELECT balance INTO v_from_balance FROM accounts WHERE account_id = v_from_account_id;
        SELECT balance INTO v_to_balance FROM accounts WHERE account_id = v_to_account_id;

        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, changed_at)
        VALUES ('transactions', v_new_transaction_id, 'INSERT',
            jsonb_build_object('from_account', p_from_account_number, 'to_account', p_to_account_number, 'amount', p_amount),
            'system', CURRENT_TIMESTAMP);

        RETURN QUERY SELECT TRUE, v_new_transaction_id, NULL::VARCHAR, NULL::TEXT, v_from_balance, v_to_balance;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, changed_at)
        VALUES ('transactions', 0, 'INSERT',
            jsonb_build_object('error', SQLERRM, 'error_code', COALESCE(v_error_code, 'ERR_UNKNOWN')),
            'system', CURRENT_TIMESTAMP);

        RETURN QUERY SELECT FALSE, NULL::INTEGER, COALESCE(v_error_code, 'ERR_UNKNOWN'),
                           COALESCE(v_error_msg, SQLERRM), v_from_balance, v_to_balance;
    END;

END;
$$ LANGUAGE plpgsql;

--task 2
CREATE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    c.status,
    c.daily_limit_kzt,
    COUNT(a.account_id) as account_count,
    STRING_AGG(DISTINCT a.currency, ', ') as currencies,
    SUM(
        CASE
            WHEN a.currency = 'KZT' THEN a.balance
            WHEN a.currency = 'USD' THEN a.balance * 476.19
            WHEN a.currency = 'EUR' THEN a.balance * 526.32
            WHEN a.currency = 'RUB' THEN a.balance * 24.39
            ELSE 0
        END
    ) as total_balance_kzt,
    COALESCE(
        ROUND(100.0 * COALESCE((
            SELECT SUM(amount_kzt)
            FROM transactions
            WHERE from_account_id IN (SELECT account_id FROM accounts WHERE customer_id = c.customer_id)
              AND DATE(created_at) = CURRENT_DATE
              AND status IN ('completed', 'pending')
        ), 0) / NULLIF(c.daily_limit_kzt, 0), 2),
        0
    ) as daily_limit_utilization_percent,
    RANK() OVER (ORDER BY SUM(
        CASE
            WHEN a.currency = 'KZT' THEN a.balance
            WHEN a.currency = 'USD' THEN a.balance * 476.19
            WHEN a.currency = 'EUR' THEN a.balance * 526.32
            WHEN a.currency = 'RUB' THEN a.balance * 24.39
            ELSE 0
        END
    ) DESC) as balance_rank
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id AND a.is_active = TRUE
GROUP BY c.customer_id, c.full_name, c.email, c.status, c.daily_limit_kzt;

CREATE VIEW daily_transaction_report AS
SELECT
    DATE(t.created_at) as transaction_date,
    t.type,
    COUNT(*) as transaction_count,
    SUM(t.amount_kzt) as total_volume_kzt,
    AVG(t.amount_kzt) as avg_amount_kzt,
    MIN(t.amount_kzt) as min_amount_kzt,
    MAX(t.amount_kzt) as max_amount_kzt,
    SUM(SUM(t.amount_kzt)) OVER (
        PARTITION BY t.type
        ORDER BY DATE(t.created_at)
    ) as running_total_kzt,
    ROUND(
        100.0 * (SUM(t.amount_kzt) - LAG(SUM(t.amount_kzt)) OVER (
            PARTITION BY t.type
            ORDER BY DATE(t.created_at)
        )) / NULLIF(LAG(SUM(t.amount_kzt)) OVER (
            PARTITION BY t.type
            ORDER BY DATE(t.created_at)
        ), 0),
        2
    ) as day_over_day_growth_percent
FROM transactions t
WHERE t.status IN ('completed', 'pending')
GROUP BY DATE(t.created_at), t.type;

CREATE VIEW suspicious_activity_view WITH (security_barrier = true) AS
WITH transaction_stats AS (
    SELECT
        t.transaction_id,
        t.from_account_id,
        t.to_account_id,
        t.amount_kzt,
        t.created_at,
        LAG(t.created_at) OVER (PARTITION BY t.from_account_id ORDER BY t.created_at) as prev_created_at
    FROM transactions t
),
hourly_stats AS (
    SELECT
        from_account_id,
        DATE_TRUNC('hour', created_at) as hour_bucket,
        COUNT(*) as count_in_hour
    FROM transactions
    GROUP BY 1, 2
)
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    a.account_number as from_account,
    a2.account_number as to_account,
    c.full_name as customer_name,
    t.amount_kzt,
    t.created_at,
    CASE
        WHEN t.amount_kzt > 5000000 THEN 'Large Amount'
        WHEN h.count_in_hour > 10 THEN 'Rapid Transactions'
        WHEN EXTRACT(EPOCH FROM (t.created_at - ts.prev_created_at)) < 60 THEN 'Rapid Sequential Transfers'
        ELSE NULL
    END as suspicious_flag
FROM transactions t
JOIN transaction_stats ts ON t.transaction_id = ts.transaction_id
LEFT JOIN accounts a ON t.from_account_id = a.account_id
LEFT JOIN accounts a2 ON t.to_account_id = a2.account_id
LEFT JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN hourly_stats h ON t.from_account_id = h.from_account_id
    AND DATE_TRUNC('hour', t.created_at) = h.hour_bucket
WHERE t.amount_kzt > 5000000
   OR h.count_in_hour > 10
   OR EXTRACT(EPOCH FROM (t.created_at - ts.prev_created_at)) < 60;

--task 3
CREATE INDEX idx_accounts_status_currency ON accounts(is_active, currency);
CREATE INDEX idx_customers_iin ON customers USING HASH (iin);
CREATE INDEX idx_accounts_active_only ON accounts(customer_id, currency) WHERE is_active = TRUE;
CREATE INDEX idx_customers_email_lower ON customers(LOWER(email));
CREATE INDEX idx_audit_log_jsonb ON audit_log USING GIN(new_values);
CREATE INDEX idx_accounts_covering ON accounts(account_number, is_active) INCLUDE (balance, currency, customer_id);
CREATE INDEX idx_transactions_from_date ON transactions(from_account_id, created_at DESC);
CREATE INDEX idx_transactions_status ON transactions(status, created_at);

--task 4
CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_account_number VARCHAR,
    p_payments JSONB
)
RETURNS TABLE (
    successful_count INTEGER,
    failed_count INTEGER,
    failed_details JSONB,
    total_processed DECIMAL,
    status_message TEXT
) AS $$
DECLARE
    v_company_account_id INTEGER;
    v_company_balance DECIMAL;
    v_total_batch_amount DECIMAL;
    v_lock_id INTEGER;
    v_lock_acquired BOOLEAN;
    v_payment JSONB;
    v_payment_iin VARCHAR;
    v_payment_amount DECIMAL;
    v_payment_description TEXT;
    v_recipient_customer_id INTEGER;
    v_recipient_account_id INTEGER;
    v_successful_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_failed_array JSONB := '[]'::JSONB;
    v_total_processed DECIMAL := 0;
    v_exchange_rate DECIMAL;
    v_amount_kzt DECIMAL;
    v_recipient_balance DECIMAL;
    v_new_transaction_id INTEGER;
    i INTEGER := 0;
BEGIN
    BEGIN
        v_lock_id := (hashtext(p_company_account_number))::INTEGER;

        PERFORM pg_advisory_lock_shared(v_lock_id, 1);

        SELECT account_id, balance, customer_id
        INTO v_company_account_id, v_company_balance, v_recipient_customer_id
        FROM accounts
        WHERE account_number = p_company_account_number AND is_active = TRUE
        FOR UPDATE;

        IF v_company_account_id IS NULL THEN
            RAISE EXCEPTION 'Company account not found';
        END IF;

        v_total_batch_amount := 0;
        FOR v_payment IN SELECT jsonb_array_elements(p_payments) LOOP
            v_total_batch_amount := v_total_batch_amount + (v_payment->>'amount')::DECIMAL;
        END LOOP;

        IF v_company_balance < v_total_batch_amount THEN
            RAISE EXCEPTION 'Insufficient company account balance for batch processing';
        END IF;

        FOR v_payment IN SELECT jsonb_array_elements(p_payments) LOOP
            i := i + 1;
            v_payment_iin := v_payment->>'iin';
            v_payment_amount := (v_payment->>'amount')::DECIMAL;
            v_payment_description := COALESCE(v_payment->>'description', 'Salary payment batch ' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD'));


            BEGIN
                SELECT customer_id
                INTO v_recipient_customer_id
                FROM customers
                WHERE iin = v_payment_iin;

                IF v_recipient_customer_id IS NULL THEN
                    v_failed_count := v_failed_count + 1;
                    v_failed_array := v_failed_array || jsonb_build_array(
                        jsonb_build_object(
                            'iin', v_payment_iin,
                            'amount', v_payment_amount,
                            'error', 'Customer not found'
                        )
                    );
                    CONTINUE;
                END IF;

                SELECT account_id
                INTO v_recipient_account_id
                FROM accounts
                WHERE customer_id = v_recipient_customer_id
                  AND currency = 'KZT'
                  AND is_active = TRUE
                LIMIT 1;

                IF v_recipient_account_id IS NULL THEN
                    v_failed_count := v_failed_count + 1;
                    v_failed_array := v_failed_array || jsonb_build_array(
                        jsonb_build_object(
                            'iin', v_payment_iin,
                            'amount', v_payment_amount,
                            'error', 'Recipient account not found'
                        )
                    );
                    CONTINUE;
                END IF;

                INSERT INTO transactions (
                    from_account_id, to_account_id, amount, currency, exchange_rate,
                    amount_kzt, type, status, description, created_at
                ) VALUES (
                    v_company_account_id, v_recipient_account_id, v_payment_amount, 'KZT',
                    1.0, v_payment_amount, 'transfer', 'completed', v_payment_description, CURRENT_TIMESTAMP
                )
                RETURNING transaction_id INTO v_new_transaction_id;

                UPDATE accounts SET balance = balance - v_payment_amount
                WHERE account_id = v_company_account_id;

                UPDATE accounts SET balance = balance + v_payment_amount
                WHERE account_id = v_recipient_account_id;

                INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, changed_at)
                VALUES ('transactions', v_new_transaction_id, 'INSERT',
                    jsonb_build_object('batch_payment', true, 'iin', v_payment_iin, 'amount', v_payment_amount),
                    'batch_processor', CURRENT_TIMESTAMP);

                v_successful_count := v_successful_count + 1;
                v_total_processed := v_total_processed + v_payment_amount;

            EXCEPTION WHEN OTHERS THEN
                v_failed_count := v_failed_count + 1;
                v_failed_array := v_failed_array || jsonb_build_array(
                    jsonb_build_object(
                        'iin', v_payment_iin,
                        'amount', v_payment_amount,
                        'error', SQLERRM
                    )
                );
            END;
        END LOOP;

        PERFORM pg_advisory_unlock_shared(v_lock_id, 1);

        RETURN QUERY SELECT
            v_successful_count,
            v_failed_count,
            v_failed_array,
            v_total_processed,
            'Batch processing completed: ' || v_successful_count || ' successful, ' || v_failed_count || ' failed'::TEXT;

    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_advisory_unlock_shared(v_lock_id, 1);
        RAISE EXCEPTION 'Batch processing failed: %', SQLERRM;
    END;

END;
$$ LANGUAGE plpgsql;

CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT
    DATE(t.created_at) as batch_date,
    a.account_number as company_account,
    COUNT(*) as total_payments,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as avg_payment,
    MIN(t.amount) as min_payment,
    MAX(t.amount) as max_payment
FROM transactions t
JOIN accounts a ON t.from_account_id = a.account_id
WHERE (t.description LIKE 'Salary payment%' OR t.description LIKE 'Batch payment%')
  AND t.status = 'completed'
GROUP BY DATE(t.created_at), a.account_number;

CREATE INDEX idx_salary_batch_summary_date ON salary_batch_summary(batch_date DESC);
