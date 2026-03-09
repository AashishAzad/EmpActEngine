package com.tech909.empact.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Generic Paginated Response Wrapper
 *
 * Design Pattern: Generic Wrapper / Template Method
 * Reused by employees, leaves, payslips, letters — all paginated endpoints.
 *
 * Usage: PagedResponse<EmployeeResponse>, PagedResponse<LeaveResponse>, etc.
 *
 * @param <T> the type of items in the page
 */
@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class PagedResponse<T> {
    private List<T> data;
    private long total;
    private int page;
    private int limit;
    private int totalPages;

    /** Factory method — builds from Spring's Page object */
    public static <T> PagedResponse<T> of(List<T> data, long total, int page, int limit) {
        return PagedResponse.<T>builder()
                .data(data)
                .total(total)
                .page(page)
                .limit(limit)
                .totalPages((int) Math.ceil((double) total / limit))
                .build();
    }
}
