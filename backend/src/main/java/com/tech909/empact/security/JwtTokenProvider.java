package com.tech909.empact.security;


import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.UUID;

/**
 * JWT Token Provider
 *
 * Responsible for:
 * - Generating access tokens and refresh tokens
 * - Validating tokens
 * - Extracting claims (userId, role, etc.) from tokens
 *
 * Algorithm: HMAC-SHA256 (HS256) — symmetric signing
 * Token format: header.payload.signature (Base64URL encoded)
 *
 * Design Pattern: Utility/Helper Component
 * Single Responsibility: Only handles JWT operations
 */
@Component
@Slf4j
public class JwtTokenProvider {

    /**
     * Secret key loaded from application.properties
     * Must be at least 256 bits (32 chars) for HS256
     */
    @Value("${app.jwt.secret}")
    private String jwtSecret;

    /** Access token lifetime: 7 days (in milliseconds) */
    @Value("${app.jwt.expiration-ms}")
    private long jwtExpirationMs;

    /** Refresh token lifetime: 30 days (in milliseconds) */
    @Value("${app.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

    /**
     * Derives the signing key from the secret string.
     * JJWT 0.12+ requires a SecretKey object (not raw string).
     *
     * @return SecretKey for signing/verification
     */
    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(
                java.util.Base64.getEncoder().encodeToString(jwtSecret.getBytes())
        );
        return Keys.hmacShaKeyFor(keyBytes);
    }

    /**
     * Generate Access Token
     *
     * Payload (claims):
     * - sub: employee UUID (primary identifier)
     * - employeeId: human-readable ID (EMP001, MGR001, etc.)
     * - role: UserRole enum string
     * - email: employee email
     * - iat: issued-at timestamp
     * - exp: expiration timestamp
     *
     * @param userId      UUID of the employee
     * @param employeeId  Human-readable employee ID
     * @param email       Employee email
     * @param role        UserRole (EMPLOYEE, MANAGER, ADMIN)
     * @return Signed JWT access token string
     */
    public String generateAccessToken(UUID userId, String employeeId, String email, String role) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationMs);

        return Jwts.builder()
                .subject(userId.toString())              // 'sub' claim — primary user identifier
                .claim("employeeId", employeeId)         // human-readable ID
                .claim("email", email)                   // email
                .claim("role", role)                     // role for RBAC
                .claim("type", "ACCESS")                 // token type marker
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * Generate Refresh Token
     *
     * Longer lived (30 days), minimal claims.
     * Used to obtain new access tokens without re-login.
     *
     * @param userId UUID of the employee
     * @return Signed JWT refresh token string
     */
    public String generateRefreshToken(UUID userId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + refreshExpirationMs);

        return Jwts.builder()
                .subject(userId.toString())
                .claim("type", "REFRESH")
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * Extract User ID (subject) from token
     *
     * @param token JWT string
     * @return UUID string of the employee
     */
    public String extractUserId(String token) {
        return parseClaims(token).getSubject();
    }

    /**
     * Extract a specific claim from token
     *
     * @param token     JWT string
     * @param claimKey  Key of the claim (e.g., "role", "employeeId")
     * @return Claim value as String
     */
    public String extractClaim(String token, String claimKey) {
        return parseClaims(token).get(claimKey, String.class);
    }

    /**
     * Validate Token
     *
     * Checks:
     * 1. Signature is valid (not tampered)
     * 2. Token is not expired
     * 3. Token is well-formed
     *
     * @param token JWT string
     * @return true if valid, false otherwise
     */
    public boolean validateToken(String token) {
        try {
            parseClaims(token); // throws if invalid
            return true;
        } catch (MalformedJwtException e) {
            log.warn("Invalid JWT token: {}", e.getMessage());
        } catch (ExpiredJwtException e) {
            log.warn("JWT token is expired: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            log.warn("JWT token is unsupported: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            log.warn("JWT claims string is empty: {}", e.getMessage());
        } catch (SecurityException e) {
            log.warn("Invalid JWT signature: {}", e.getMessage());
        } catch (Exception e) {
            log.warn("JWT validation error: {}", e.getMessage());
        }
        return false;
    }

    /**
     * Check if token is a refresh token
     *
     * @param token JWT string
     * @return true if token type is REFRESH
     */
    public boolean isRefreshToken(String token) {
        try {
            String type = extractClaim(token, "type");
            return "REFRESH".equals(type);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Parse and return all claims from token
     * Throws JwtException if token is invalid/expired
     *
     * @param token JWT string
     * @return Claims object
     */
    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
//Random command to see Jenkins working??