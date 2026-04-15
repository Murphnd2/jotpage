package com.jotpage.servlet;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * Prevents browsers and intermediate caches from storing responses for the
 * mapped resources. Used to keep sw.js and manifest.webmanifest always fresh
 * so PWA updates propagate immediately.
 */
public class NoCacheFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        if (response instanceof HttpServletResponse) {
            HttpServletResponse http = (HttpServletResponse) response;
            http.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
            http.setHeader("Pragma", "no-cache");
            http.setHeader("Expires", "0");
        }
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}
