-- Варіант 1: Електронний журнал
-- Виконати у SQL Editor хмарної PostgreSQL (Neon)

CREATE TABLE IF NOT EXISTS journal_records (
    id BIGSERIAL PRIMARY KEY,
    student_name VARCHAR(120) NOT NULL,
    subject VARCHAR(60) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'present',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_status
        CHECK (status IN ('present', 'absent', 'late'))
);

-- Демонстраційні записи (виконувати один раз, щоб не дублювати)
INSERT INTO journal_records (student_name, subject, status) VALUES
('Шевченко Олена', 'Хмарні технології', 'present'),
('Коваленко Андрій', 'Програмування Java', 'late'),
('Бондаренко Марія', 'Бази даних', 'absent');

-- Перевірка
SELECT * FROM journal_records ORDER BY id;
