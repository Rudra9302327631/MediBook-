-- ============================================================
--  MediBook - Online Medical Checkup Booking System
--  MySQL Database Schema + Sample Data
--  Version: 1.0
-- ============================================================

CREATE DATABASE IF NOT EXISTS medibook;
USE medibook;

-- ============================================================
-- 1. CITIES
-- ============================================================
CREATE TABLE cities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. SPECIALTIES
-- ============================================================
CREATE TABLE specialties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(10),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. USERS (Patients)
-- ============================================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    gender ENUM('Male', 'Female', 'Other'),
    date_of_birth DATE,
    blood_group VARCHAR(5),
    address TEXT,
    city_id INT,
    profile_photo VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (city_id) REFERENCES cities(id)
);

-- ============================================================
-- 4. DOCTORS
-- ============================================================
CREATE TABLE doctors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    specialty_id INT NOT NULL,
    qualification VARCHAR(255),
    experience_years INT DEFAULT 0,
    hospital_name VARCHAR(200),
    city_id INT,
    bio TEXT,
    consultation_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    profile_photo VARCHAR(255),
    avg_rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INT DEFAULT 0,
    is_available_video BOOLEAN DEFAULT TRUE,
    is_available_clinic BOOLEAN DEFAULT TRUE,
    is_available_home BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (specialty_id) REFERENCES specialties(id),
    FOREIGN KEY (city_id) REFERENCES cities(id)
);

-- ============================================================
-- 5. DOCTOR SCHEDULES (Weekly availability)
-- ============================================================
CREATE TABLE doctor_schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    day_of_week ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration_mins INT DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
    UNIQUE KEY unique_schedule (doctor_id, day_of_week)
);

-- ============================================================
-- 6. HEALTH PACKAGES
-- ============================================================
CREATE TABLE health_packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    tag VARCHAR(50),                  -- e.g. 'Popular', 'Premium'
    includes_tests TEXT,              -- comma-separated test names
    includes_consultation BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. APPOINTMENTS
-- ============================================================
CREATE TABLE appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_ref VARCHAR(20) UNIQUE NOT NULL,  -- e.g. MB2024-9821
    user_id INT NOT NULL,
    doctor_id INT,
    package_id INT,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    consultation_type ENUM('In-Clinic', 'Video', 'Home Visit') NOT NULL,
    status ENUM('Pending', 'Confirmed', 'Completed', 'Cancelled', 'No Show') DEFAULT 'Pending',
    symptoms TEXT,
    notes TEXT,
    consultation_fee DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    FOREIGN KEY (package_id) REFERENCES health_packages(id)
);

-- ============================================================
-- 8. PAYMENTS
-- ============================================================
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('UPI', 'Card', 'Net Banking', 'Pay at Clinic', 'Wallet') NOT NULL,
    payment_status ENUM('Pending', 'Success', 'Failed', 'Refunded') DEFAULT 'Pending',
    transaction_id VARCHAR(100),
    coupon_code VARCHAR(50),
    discount_amount DECIMAL(10,2) DEFAULT 0,
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================================
-- 9. LAB REPORTS
-- ============================================================
CREATE TABLE lab_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    appointment_id INT,
    report_name VARCHAR(200) NOT NULL,
    file_path VARCHAR(255),
    report_date DATE,
    uploaded_by ENUM('Doctor', 'Lab', 'Patient') DEFAULT 'Lab',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id)
);

-- ============================================================
-- 10. PRESCRIPTIONS
-- ============================================================
CREATE TABLE prescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    doctor_id INT NOT NULL,
    user_id INT NOT NULL,
    medicines TEXT,         -- JSON string: [{name, dosage, duration}]
    instructions TEXT,
    follow_up_date DATE,
    file_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================================
-- 11. REVIEWS & RATINGS
-- ============================================================
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    user_id INT NOT NULL,
    doctor_id INT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    UNIQUE KEY one_review_per_appt (appointment_id, user_id)
);

-- ============================================================
-- 12. NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('Appointment', 'Payment', 'Report', 'Reminder', 'Promo') DEFAULT 'Appointment',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================================
-- 13. COUPONS
-- ============================================================
CREATE TABLE coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_type ENUM('Flat', 'Percent') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    max_uses INT DEFAULT 100,
    used_count INT DEFAULT 0,
    valid_from DATE,
    valid_until DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 14. ADMIN USERS
-- ============================================================
CREATE TABLE admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Super Admin', 'Manager', 'Support') DEFAULT 'Support',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
--  SAMPLE DATA
-- ============================================================

-- Cities
INSERT INTO cities (name, state) VALUES
('Indore', 'Madhya Pradesh'),
('Mumbai', 'Maharashtra'),
('Delhi', 'Delhi'),
('Bangalore', 'Karnataka'),
('Pune', 'Maharashtra'),
('Hyderabad', 'Telangana');

-- Specialties
INSERT INTO specialties (name, icon, description) VALUES
('General Physician', '🩺', 'Primary healthcare for common illnesses'),
('Cardiology', '❤️', 'Heart and cardiovascular system'),
('Neurology', '🧠', 'Brain and nervous system disorders'),
('Pediatrics', '👶', 'Medical care for infants and children'),
('Orthopedics', '🦴', 'Bones, joints and musculoskeletal system'),
('Dermatology', '💊', 'Skin, hair and nail conditions'),
('Ophthalmology', '👁️', 'Eye care and vision'),
('Dentistry', '🦷', 'Oral health and dental care'),
('Physiotherapy', '🏃', 'Physical rehabilitation and movement'),
('Radiology', '🔬', 'Medical imaging and diagnosis');

-- Users (passwords are bcrypt hashed — plain: "Password@123")
INSERT INTO users (full_name, email, phone, password_hash, gender, date_of_birth, blood_group, address, city_id, is_verified) VALUES
('Rahul Sharma', 'rahul@gmail.com', '9876543210', '$2b$10$examplehash1', 'Male', '1995-06-15', 'B+', '12 MG Road', 1, TRUE),
('Priya Verma', 'priya@gmail.com', '9876543211', '$2b$10$examplehash2', 'Female', '1990-03-22', 'O+', '45 Andheri West', 2, TRUE),
('Amit Patel', 'amit@gmail.com', '9876543212', '$2b$10$examplehash3', 'Male', '1988-11-10', 'A+', '78 Connaught Place', 3, TRUE),
('Sneha Joshi', 'sneha@gmail.com', '9876543213', '$2b$10$examplehash4', 'Female', '2000-07-05', 'AB+', '23 Koregaon Park', 5, FALSE),
('Vikram Singh', 'vikram@gmail.com', '9876543214', '$2b$10$examplehash5', 'Male', '1975-12-30', 'O-', '56 Banjara Hills', 6, TRUE);

-- Doctors
INSERT INTO doctors (full_name, email, phone, password_hash, specialty_id, qualification, experience_years, hospital_name, city_id, bio, consultation_fee, avg_rating, total_reviews, is_available_video, is_available_clinic, is_verified) VALUES
('Dr. Priya Sharma',    'dr.priya@medibook.in',  '9000000001', '$2b$10$dochash1', 2, 'MBBS, MD (Cardiology), AIIMS Delhi', 15, 'City Heart Hospital',   1, 'Specialist in cardiac care with 15 years of clinical experience.', 800.00,  4.9, 142, TRUE,  TRUE,  TRUE),
('Dr. Arjun Mehta',    'dr.arjun@medibook.in',  '9000000002', '$2b$10$dochash2', 3, 'MBBS, DM (Neurology), KEM Mumbai',  12, 'Bombay Neuro Center',   2, 'Expert neurologist managing stroke and epilepsy cases.',           1000.00, 4.8, 98,  FALSE, TRUE,  TRUE),
('Dr. Neha Gupta',     'dr.neha@medibook.in',   '9000000003', '$2b$10$dochash3', 4, 'MBBS, MD (Pediatrics), MGM Indore', 10, 'Rainbow Kids Clinic',   1, 'Caring pediatrician dedicated to child health and wellness.',        600.00,  4.7, 76,  TRUE,  TRUE,  TRUE),
('Dr. Rahul Verma',    'dr.rahul@medibook.in',  '9000000004', '$2b$10$dochash4', 5, 'MBBS, MS (Ortho), Fortis Delhi',    18, 'Fortis Bone & Joint',   3, 'Senior orthopedic surgeon specializing in joint replacements.',     1200.00, 5.0, 210, FALSE, TRUE,  TRUE),
('Dr. Kavita Patel',   'dr.kavita@medibook.in', '9000000005', '$2b$10$dochash5', 6, 'MBBS, MD (Derm), Bombay Hospital',  8,  'Skin & Glow Clinic',    2, 'Dermatologist with expertise in acne, pigmentation and hair loss.',  700.00,  4.6, 55,  TRUE,  TRUE,  TRUE),
('Dr. Sunil Joshi',    'dr.sunil@medibook.in',  '9000000006', '$2b$10$dochash6', 1, 'MBBS, MD (General), City Hospital', 20, 'City Medical Center',   1, 'Trusted general physician available 7 days for all age groups.',     400.00,  4.9, 320, TRUE,  TRUE,  TRUE);

-- Doctor Schedules
INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, slot_duration_mins) VALUES
(1, 'Monday',    '09:00:00', '17:00:00', 30),
(1, 'Wednesday', '09:00:00', '17:00:00', 30),
(1, 'Friday',    '09:00:00', '13:00:00', 30),
(2, 'Tuesday',   '11:00:00', '19:00:00', 30),
(2, 'Thursday',  '11:00:00', '19:00:00', 30),
(2, 'Saturday',  '10:00:00', '14:00:00', 30),
(3, 'Monday',    '10:00:00', '16:00:00', 30),
(3, 'Tuesday',   '10:00:00', '16:00:00', 30),
(3, 'Thursday',  '10:00:00', '16:00:00', 30),
(4, 'Monday',    '08:00:00', '14:00:00', 45),
(4, 'Wednesday', '08:00:00', '14:00:00', 45),
(4, 'Saturday',  '08:00:00', '12:00:00', 45),
(5, 'Wednesday', '13:00:00', '20:00:00', 30),
(5, 'Friday',    '13:00:00', '20:00:00', 30),
(5, 'Sunday',    '10:00:00', '14:00:00', 30),
(6, 'Monday',    '08:00:00', '20:00:00', 20),
(6, 'Tuesday',   '08:00:00', '20:00:00', 20),
(6, 'Wednesday', '08:00:00', '20:00:00', 20),
(6, 'Thursday',  '08:00:00', '20:00:00', 20),
(6, 'Friday',    '08:00:00', '20:00:00', 20),
(6, 'Saturday',  '08:00:00', '20:00:00', 20),
(6, 'Sunday',    '08:00:00', '20:00:00', 20);

-- Health Packages
INSERT INTO health_packages (name, description, price, original_price, tag, includes_tests, includes_consultation) VALUES
('Basic Wellness',
 'Ideal for regular health monitoring. Covers essential blood and urine tests.',
 499.00, 799.00, NULL,
 'CBC,Blood Sugar (Fasting),Urine Routine,Blood Pressure Check,BMI Assessment',
 TRUE),

('Full Body Checkup',
 'Most chosen package. Comprehensive tests covering major organs and systems.',
 1299.00, 1999.00, 'Popular',
 'CBC,Blood Sugar,Urine Routine,Lipid Profile,Liver Function Test,Kidney Function Test,Thyroid (T3 T4 TSH),ECG,Chest X-Ray',
 TRUE),

('Premium Executive',
 'Complete health assessment with priority consultation and home collection.',
 2999.00, 4499.00, 'Premium',
 'All Full Body Tests,Vitamin D,Vitamin B12,Cancer Markers,Bone Density Scan,Eye Check,Dental Check,Stress Test,Nutritionist Consultation',
 TRUE);

-- Appointments
INSERT INTO appointments (booking_ref, user_id, doctor_id, package_id, appointment_date, appointment_time, consultation_type, status, symptoms, consultation_fee) VALUES
('MB2024-0001', 1, 1, NULL, '2025-05-01', '10:00:00', 'Video',     'Confirmed', 'Chest pain and breathlessness',    800.00),
('MB2024-0002', 1, NULL, 2,  '2025-05-05', '08:30:00', 'In-Clinic', 'Pending',   'Annual full body checkup',         1299.00),
('MB2024-0003', 1, 6, NULL,  '2025-04-10', '11:00:00', 'In-Clinic', 'Completed', 'Fever and cold for 3 days',        400.00),
('MB2024-0004', 1, 3, NULL,  '2025-03-22', '15:00:00', 'Video',     'Cancelled', 'Child vaccination follow-up',      600.00),
('MB2024-0005', 2, 4, NULL,  '2025-04-28', '09:00:00', 'In-Clinic', 'Completed', 'Knee pain after running',          1200.00),
('MB2024-0006', 3, 5, NULL,  '2025-05-03', '14:00:00', 'Video',     'Confirmed', 'Acne and dark spots on face',      700.00),
('MB2024-0007', 4, 2, NULL,  '2025-05-07', '11:00:00', 'In-Clinic', 'Pending',   'Recurring headaches and dizziness',1000.00),
('MB2024-0008', 5, 1, NULL,  '2025-04-15', '09:30:00', 'Video',     'Completed', 'Post-surgery cardiac checkup',     800.00);

-- Payments
INSERT INTO payments (appointment_id, user_id, amount, payment_method, payment_status, transaction_id, paid_at) VALUES
(1, 1, 800.00,  'UPI',          'Success', 'TXN20240501001', '2025-04-30 18:22:10'),
(2, 1, 1299.00, 'Card',         'Pending', NULL,             NULL),
(3, 1, 400.00,  'UPI',          'Success', 'TXN20240410001', '2025-04-10 10:45:00'),
(4, 1, 0.00,    'Pay at Clinic','Refunded','REF20240322001', '2025-03-23 09:00:00'),
(5, 2, 1200.00, 'Net Banking',  'Success', 'TXN20240428001', '2025-04-27 20:15:00'),
(6, 3, 700.00,  'UPI',          'Success', 'TXN20240503001', '2025-05-02 16:30:00'),
(7, 4, 1000.00, 'Card',         'Pending', NULL,             NULL),
(8, 5, 800.00,  'Wallet',       'Success', 'TXN20240415001', '2025-04-15 08:00:00');

-- Lab Reports
INSERT INTO lab_reports (user_id, appointment_id, report_name, report_date, uploaded_by) VALUES
(1, 3, 'Complete Blood Count (CBC)',  '2025-04-10', 'Lab'),
(1, 3, 'Lipid Profile',              '2025-04-10', 'Lab'),
(1, 8, 'ECG Report',                 '2025-04-15', 'Doctor'),
(2, 5, 'X-Ray Right Knee',           '2025-04-28', 'Lab'),
(5, 8, 'Echocardiography Report',    '2025-04-15', 'Doctor');

-- Prescriptions
INSERT INTO prescriptions (appointment_id, doctor_id, user_id, medicines, instructions, follow_up_date) VALUES
(3, 6, 1,
 '[{"name":"Paracetamol 500mg","dosage":"1 tablet","duration":"3 days"},{"name":"Cetirizine 10mg","dosage":"1 tablet at night","duration":"5 days"}]',
 'Rest well, drink plenty of fluids. Avoid cold drinks.',
 '2025-04-20'),
(5, 4, 2,
 '[{"name":"Diclofenac 50mg","dosage":"1 tablet after meals","duration":"7 days"},{"name":"Calcium + D3","dosage":"1 tablet daily","duration":"30 days"}]',
 'Avoid running. Do light stretching exercises. Apply ice pack if needed.',
 '2025-05-28');

-- Reviews
INSERT INTO reviews (appointment_id, user_id, doctor_id, rating, review_text, is_approved) VALUES
(3, 1, 6, 5, 'Dr. Sunil was very thorough and explained everything clearly. Quick recovery!', TRUE),
(5, 2, 4, 5, 'Dr. Rahul is an excellent surgeon. My knee pain is completely gone after following his advice.', TRUE),
(8, 5, 1, 5, 'Dr. Priya is amazing. She was very patient and detailed in her cardiac assessment.', TRUE);

-- Coupons
INSERT INTO coupons (code, discount_type, discount_value, min_order_amount, max_uses, valid_from, valid_until) VALUES
('FIRST50',   'Flat',    50.00,  0,      500, '2025-01-01', '2025-12-31'),
('HEALTH20',  'Percent', 20.00,  500,    200, '2025-04-01', '2025-06-30'),
('WELCOME100','Flat',    100.00, 999,    300, '2025-01-01', '2025-12-31'),
('SUMMER15',  'Percent', 15.00,  1000,   150, '2025-05-01', '2025-07-31');

-- Notifications
INSERT INTO notifications (user_id, title, message, type, is_read) VALUES
(1, 'Appointment Confirmed ✅', 'Your appointment with Dr. Priya Sharma on May 1 at 10:00 AM is confirmed.', 'Appointment', FALSE),
(1, 'Reminder 🔔',              'You have an appointment tomorrow at 10:00 AM. Please be ready 5 minutes early.', 'Reminder', FALSE),
(1, 'Lab Report Ready 🧪',      'Your CBC report from April 10 is now available. Download it from Health Records.', 'Report', TRUE),
(2, 'Appointment Completed ✅', 'Your appointment with Dr. Rahul Verma is marked complete. Rate your experience!', 'Appointment', TRUE),
(3, 'Payment Successful 💳',    'Payment of ₹700 received for appointment with Dr. Kavita Patel.', 'Payment', FALSE);

-- Admin
INSERT INTO admins (full_name, email, password_hash, role) VALUES
('Super Admin',   'admin@medibook.in',   '$2b$10$adminhash1', 'Super Admin'),
('Support Agent', 'support@medibook.in', '$2b$10$adminhash2', 'Support');


-- ============================================================
--  USEFUL QUERIES FOR YOUR APP
-- ============================================================

-- 1. Get all upcoming appointments for a user
-- SELECT a.*, d.full_name AS doctor_name, s.name AS specialty
-- FROM appointments a
-- LEFT JOIN doctors d ON a.doctor_id = d.id
-- LEFT JOIN specialties s ON d.specialty_id = s.id
-- WHERE a.user_id = 1 AND a.appointment_date >= CURDATE()
-- ORDER BY a.appointment_date, a.appointment_time;

-- 2. Get available doctors by specialty
-- SELECT d.*, s.name AS specialty, c.name AS city
-- FROM doctors d
-- JOIN specialties s ON d.specialty_id = s.id
-- JOIN cities c ON d.city_id = c.id
-- WHERE d.specialty_id = 2 AND d.is_active = TRUE AND d.is_verified = TRUE
-- ORDER BY d.avg_rating DESC;

-- 3. Get doctor's available time slots for a day
-- SELECT ds.start_time, ds.end_time, ds.slot_duration_mins
-- FROM doctor_schedules ds
-- WHERE ds.doctor_id = 1 AND ds.day_of_week = 'Monday' AND ds.is_active = TRUE;

-- 4. Get all lab reports for a user
-- SELECT lr.*, a.appointment_date
-- FROM lab_reports lr
-- LEFT JOIN appointments a ON lr.appointment_id = a.id
-- WHERE lr.user_id = 1
-- ORDER BY lr.report_date DESC;

-- 5. Revenue report (admin)
-- SELECT DATE_FORMAT(paid_at, '%Y-%m') AS month,
--        SUM(amount) AS total_revenue,
--        COUNT(*) AS total_transactions
-- FROM payments
-- WHERE payment_status = 'Success'
-- GROUP BY month
-- ORDER BY month DESC;

-- 6. Top rated doctors
-- SELECT d.full_name, s.name AS specialty, d.avg_rating, d.total_reviews, d.consultation_fee
-- FROM doctors d
-- JOIN specialties s ON d.specialty_id = s.id
-- WHERE d.is_active = TRUE
-- ORDER BY d.avg_rating DESC, d.total_reviews DESC
-- LIMIT 10;
