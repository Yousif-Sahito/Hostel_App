

CREATE DATABASE IF NOT EXISTS hostel_mess_db;
USE hostel_mess_db;

-- =========================
-- USER TABLE
-- =========================
CREATE TABLE User (
    id INT NOT NULL AUTO_INCREMENT,
    fullName VARCHAR(191) NOT NULL,
    email VARCHAR(191) NULL,
    cmsId VARCHAR(191) NULL,
    phone VARCHAR(191) NULL,
    passwordHash VARCHAR(191) NOT NULL,
    role ENUM('ADMIN', 'MEMBER') NOT NULL,
    status ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    roomId INT NULL,
    joiningDate DATETIME(3) NULL,
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY User_email_key (email),
    UNIQUE KEY User_cmsId_key (cmsId)
);

-- =========================
-- ROOM TABLE
-- =========================
CREATE TABLE Room (
    id INT NOT NULL AUTO_INCREMENT,
    roomNumber VARCHAR(191) NOT NULL,
    capacity INT NOT NULL,
    occupiedCount INT NOT NULL DEFAULT 0,
    status ENUM('AVAILABLE', 'FULL', 'MAINTENANCE') NOT NULL DEFAULT 'AVAILABLE',
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY Room_roomNumber_key (roomNumber)
);

-- =========================
-- HOSTEL SETTING TABLE
-- =========================
CREATE TABLE HostelSetting (
    id INT NOT NULL AUTO_INCREMENT,
    hostelName VARCHAR(191) NOT NULL,
    breakfastPrice DOUBLE NOT NULL,
    lunchPrice DOUBLE NOT NULL,
    dinnerPrice DOUBLE NOT NULL,
    guestMealPrice DOUBLE NOT NULL,
    messStatus ENUM('ON', 'OFF') NOT NULL DEFAULT 'ON',
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id)
);

-- =========================
-- WEEKLY MENU TABLE
-- =========================
CREATE TABLE WeeklyMenu (
    id INT NOT NULL AUTO_INCREMENT,
    weekStartDate DATETIME(3) NOT NULL,
    createdBy INT NOT NULL,
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    INDEX WeeklyMenu_createdBy_fkey (createdBy)
);

-- =========================
-- WEEKLY MENU ITEM TABLE
-- =========================
CREATE TABLE WeeklyMenuItem (
    id INT NOT NULL AUTO_INCREMENT,
    weeklyMenuId INT NOT NULL,
    dayName VARCHAR(191) NOT NULL,
    breakfast VARCHAR(191) NOT NULL,
    lunch VARCHAR(191) NOT NULL,
    dinner VARCHAR(191) NOT NULL,
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    INDEX WeeklyMenuItem_weeklyMenuId_fkey (weeklyMenuId)
);

-- =========================
-- MEAL ENTRY TABLE
-- =========================
CREATE TABLE MealEntry (
    id INT NOT NULL AUTO_INCREMENT,
    userId INT NOT NULL,
    mealDate DATETIME(3) NOT NULL,
    breakfastTaken BOOLEAN NOT NULL DEFAULT FALSE,
    lunchTaken BOOLEAN NOT NULL DEFAULT FALSE,
    dinnerTaken BOOLEAN NOT NULL DEFAULT FALSE,
    guestCount INT NOT NULL DEFAULT 0,
    createdBy INT NULL,
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY MealEntry_userId_mealDate_key (userId, mealDate),
    INDEX MealEntry_userId_fkey (userId)
);

-- =========================
-- MESS OFF PERIOD TABLE
-- =========================
CREATE TABLE MessOffPeriod (
    id INT NOT NULL AUTO_INCREMENT,
    userId INT NOT NULL,
    fromDate DATETIME(3) NOT NULL,
    toDate DATETIME(3) NOT NULL,
    reason VARCHAR(191) NULL,
    status ENUM('ACTIVE', 'CANCELLED', 'COMPLETED') NOT NULL DEFAULT 'ACTIVE',
    createdBy INT NOT NULL,
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    INDEX MessOffPeriod_userId_fkey (userId),
    INDEX MessOffPeriod_createdBy_fkey (createdBy)
);

-- =========================
-- HELPER CHARGE TABLE
-- =========================
CREATE TABLE HelperCharge (
    id INT NOT NULL AUTO_INCREMENT,
    month INT NOT NULL,
    year INT NOT NULL,
    totalAmount DOUBLE NOT NULL,
    perMemberAmount DOUBLE NOT NULL,
    notes VARCHAR(191) NULL,
    createdBy INT NOT NULL,
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    INDEX HelperCharge_createdBy_fkey (createdBy)
);

-- =========================
-- BILL TABLE
-- =========================
CREATE TABLE Bill (
    id INT NOT NULL AUTO_INCREMENT,
    userId INT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL,
    breakfastUnits INT NOT NULL DEFAULT 0,
    lunchUnits INT NOT NULL DEFAULT 0,
    dinnerUnits INT NOT NULL DEFAULT 0,
    guestUnits INT NOT NULL DEFAULT 0,
    helperCharge DOUBLE NOT NULL DEFAULT 0,
    extraCharges DOUBLE NOT NULL DEFAULT 0,
    totalAmount DOUBLE NOT NULL DEFAULT 0,
    paidAmount DOUBLE NOT NULL DEFAULT 0,
    dueAmount DOUBLE NOT NULL DEFAULT 0,
    paymentStatus ENUM('PAID', 'PARTIAL', 'UNPAID') NOT NULL DEFAULT 'UNPAID',
    generatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updatedAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    UNIQUE KEY Bill_userId_month_year_key (userId, month, year),
    INDEX Bill_userId_fkey (userId)
);

-- =========================
-- PAYMENT TABLE
-- =========================
CREATE TABLE Payment (
    id INT NOT NULL AUTO_INCREMENT,
    billId INT NOT NULL,
    userId INT NOT NULL,
    amount DOUBLE NOT NULL,
    paymentMethod ENUM('CASH', 'BANK', 'JAZZCASH', 'EASYPAISA', 'OTHER') NOT NULL,
    paymentDate DATETIME(3) NOT NULL,
    referenceNo VARCHAR(191) NULL,
    notes VARCHAR(191) NULL,
    receivedBy INT NULL,
    createdAt DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    INDEX Payment_billId_fkey (billId),
    INDEX Payment_userId_fkey (userId),
    INDEX Payment_receivedBy_fkey (receivedBy)
);

-- =========================
-- FOREIGN KEYS
-- =========================

ALTER TABLE User
ADD CONSTRAINT User_roomId_fkey
FOREIGN KEY (roomId) REFERENCES Room(id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE WeeklyMenu
ADD CONSTRAINT WeeklyMenu_createdBy_fkey
FOREIGN KEY (createdBy) REFERENCES User(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE WeeklyMenuItem
ADD CONSTRAINT WeeklyMenuItem_weeklyMenuId_fkey
FOREIGN KEY (weeklyMenuId) REFERENCES WeeklyMenu(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE MealEntry
ADD CONSTRAINT MealEntry_userId_fkey
FOREIGN KEY (userId) REFERENCES User(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE MessOffPeriod
ADD CONSTRAINT MessOffPeriod_userId_fkey
FOREIGN KEY (userId) REFERENCES User(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE MessOffPeriod
ADD CONSTRAINT MessOffPeriod_createdBy_fkey
FOREIGN KEY (createdBy) REFERENCES User(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE HelperCharge
ADD CONSTRAINT HelperCharge_createdBy_fkey
FOREIGN KEY (createdBy) REFERENCES User(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE Bill
ADD CONSTRAINT Bill_userId_fkey
FOREIGN KEY (userId) REFERENCES User(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE Payment
ADD CONSTRAINT Payment_billId_fkey
FOREIGN KEY (billId) REFERENCES Bill(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE Payment
ADD CONSTRAINT Payment_userId_fkey
FOREIGN KEY (userId) REFERENCES User(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE Payment
ADD CONSTRAINT Payment_receivedBy_fkey
FOREIGN KEY (receivedBy) REFERENCES User(id)
ON DELETE SET NULL
ON UPDATE CASCADE;

-- =========================
-- DEFAULT HOSTEL SETTINGS
-- =========================
INSERT INTO HostelSetting
(hostelName, breakfastPrice, lunchPrice, dinnerPrice, guestMealPrice, messStatus, createdAt, updatedAt)
VALUES
('My Hostel', 80, 150, 150, 200, 'ON', NOW(3), NOW(3));
INSERT INTO User
(fullName, email, passwordHash, role, status, createdAt, updatedAt)
VALUES
('System Admin', 'admin@hostel.com', 'PUT_BCRYPT_HASH_HERE', 'ADMIN', 'ACTIVE', NOW(3), NOW(3));

SELECT * FROM User;
SELECT * FROM Room;
SELECT * FROM HostelSetting;
SELECT * FROM WeeklyMenu;
SELECT * FROM WeeklyMenuItem;
SELECT * FROM MealEntry;
SELECT * FROM MessOffPeriod;
SELECT * FROM HelperCharge;
SELECT * FROM Bill;
SELECT * FROM Payment;
INSERT INTO Room (roomNumber, capacity, occupiedCount, status, createdAt, updatedAt)
VALUES ('A-101', 3, 0, 'AVAILABLE', NOW(3), NOW(3));

