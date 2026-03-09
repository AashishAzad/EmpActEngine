package com.tech909.empact.config;

import com.tech909.empact.entity.CompanyHoliday;
import com.tech909.empact.entity.Salary;
import com.tech909.empact.entity.User;
import com.tech909.empact.enums.EmployeeStatus;
import com.tech909.empact.enums.UserRole;
import com.tech909.empact.repository.CompanyHolidayRepository;
import com.tech909.empact.repository.SalaryRepository;
import com.tech909.empact.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements ApplicationRunner {

    private final UserRepository userRepository;
    private final SalaryRepository salaryRepository;
    private final CompanyHolidayRepository holidayRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        log.info("🌱 Running DataSeeder...");
        seedUsers();
        seedSalaries();
        seedHolidays();
        log.info("✅ DataSeeder complete.");
    }

    private void seedUsers() {
        String defaultPassword = passwordEncoder.encode("password123");

        List<UserSeed> seeds = List.of(
                new UserSeed("ADM001", "System",  "Admin",  "admin@company.com",
                        UserRole.ADMIN,    "System Administrator", "Management",  defaultPassword),
                new UserSeed("MGR001", "Rajesh",  "Kumar",  "rajesh.kumar@company.com",
                        UserRole.MANAGER,  "Engineering Manager",  "Engineering", defaultPassword),
                new UserSeed("MGR002", "Priya",   "Sharma", "priya.sharma@company.com",
                        UserRole.MANAGER,  "HR Manager",           "HR",          defaultPassword),
                new UserSeed("EMP001", "Amit",    "Singh",  "amit.singh@company.com",
                        UserRole.EMPLOYEE, "Software Engineer",    "Engineering", defaultPassword),
                new UserSeed("EMP002", "Neha",    "Gupta",  "neha.gupta@company.com",
                        UserRole.EMPLOYEE, "Frontend Developer",   "Engineering", defaultPassword),
                new UserSeed("EMP003", "Vikram",  "Patel",  "vikram.patel@company.com",
                        UserRole.EMPLOYEE, "QA Engineer",          "QA",          defaultPassword)
        );

        int created = 0;
        for (UserSeed seed : seeds) {
            if (!userRepository.existsByEmployeeId(seed.employeeId())) {
                User user = new User();
                user.setId(UUID.randomUUID()); // ← Required: @JmixGeneratedValue only fires via Jmix DataManager,
                //   not Spring Data JPA save(). We must assign the UUID ourselves.
                user.setEmployeeId(seed.employeeId());
                user.setUsername(seed.employeeId());
                user.setFirstName(seed.firstName());
                user.setLastName(seed.lastName());
                user.setEmail(seed.email());
                user.setRole(seed.role());
                user.setStatus(EmployeeStatus.ACTIVE);
                user.setDesignation(seed.designation());
                user.setDepartment(seed.department());
                user.setDateOfJoining(LocalDate.now().minusMonths(6));
                user.setPassword(seed.password());
                user.setActive(true);
                user.setCasualLeaveBalance(8);
                user.setSickLeaveBalance(8);
                user.setAllPurposeLeaveBalance(10);
                userRepository.save(user);
                created++;
                log.info("  👤 Created user: {} ({})", seed.employeeId(), seed.role());
            }
        }

        if (created == 0) {
            log.info("  ✓ Users already seeded, skipping");
        } else {
            log.info("  ✅ Created {} users", created);
        }
    }

    private void seedSalaries() {
        List<SalarySeed> seeds = List.of(
                new SalarySeed("ADM001", 80000, 32000, 20000, 5000, 9600, 200, 0),
                new SalarySeed("MGR001", 70000, 28000, 17000, 4000, 8400, 200, 0),
                new SalarySeed("MGR002", 65000, 26000, 15000, 3000, 7800, 200, 0),
                new SalarySeed("EMP001", 50000, 20000, 12000, 2000, 6000, 200, 0),
                new SalarySeed("EMP002", 45000, 18000, 10000, 1500, 5400, 200, 0),
                new SalarySeed("EMP003", 40000, 16000,  9000, 1000, 4800, 200, 0)
        );

        int created = 0;
        for (SalarySeed seed : seeds) {
            userRepository.findByEmployeeId(seed.employeeId()).ifPresent(user -> {
                if (!salaryRepository.existsByEmployee_Id(user.getId())) {
                    double gross = seed.basic() + seed.hra() + seed.special() + seed.other();
                    double deductions = seed.pf() + seed.pt() + seed.otherDed();
                    Salary salary = Salary.builder()
                            .id(UUID.randomUUID())
                            .employee(user)
                            .basicPay((double) seed.basic())
                            .hra((double) seed.hra())
                            .specialAllowance((double) seed.special())
                            .otherAllowances((double) seed.other())
                            .pf((double) seed.pf())
                            .professionalTax((double) seed.pt())
                            .otherDeductions((double) seed.otherDed())
                            .netPay(gross - deductions)
                            .build();
                    salaryRepository.save(salary);
                }
            });
            created++;
        }
        log.info("  ✅ Salary structures seeded for {} users", created);
    }

    private void seedHolidays() {
        int year = LocalDate.now().getYear();

        List<HolidaySeed> holidays = List.of(
                new HolidaySeed("New Year's Day",       LocalDate.of(year, 1,  1),  true),
                new HolidaySeed("Republic Day",         LocalDate.of(year, 1,  26), true),
                new HolidaySeed("Holi",                 LocalDate.of(year, 3,  14), false),
                new HolidaySeed("Good Friday",          LocalDate.of(year, 4,  18), false),
                new HolidaySeed("Maharashtra Day",      LocalDate.of(year, 5,  1),  false),
                new HolidaySeed("Independence Day",     LocalDate.of(year, 8,  15), true),
                new HolidaySeed("Gandhi Jayanti",       LocalDate.of(year, 10, 2),  true),
                new HolidaySeed("Dussehra",             LocalDate.of(year, 10, 2),  false),
                new HolidaySeed("Diwali",               LocalDate.of(year, 10, 20), false),
                new HolidaySeed("Diwali (Laxmi Pujan)", LocalDate.of(year, 10, 21), false),
                new HolidaySeed("Christmas",            LocalDate.of(year, 12, 25), true)
        );

        int created = 0;
        for (HolidaySeed h : holidays) {
            if (!holidayRepository.existsByDate(h.date())) {
                holidayRepository.save(CompanyHoliday.builder()
                        .id(UUID.randomUUID())
                        .name(h.name())
                        .date(h.date())
                        .isRecurring(h.recurring())
                        .build());
                created++;
            }
        }

        if (created > 0) {
            log.info("  ✅ Seeded {} company holidays for {}", created, year);
        } else {
            log.info("  ✓ Holidays already seeded, skipping");
        }
    }

    private record UserSeed(
            String employeeId, String firstName, String lastName,
            String email, UserRole role, String designation,
            String department, String password) {}

    private record SalarySeed(
            String employeeId, int basic, int hra, int special,
            int other, int pf, int pt, int otherDed) {}

    private record HolidaySeed(String name, LocalDate date, boolean recurring) {}
}