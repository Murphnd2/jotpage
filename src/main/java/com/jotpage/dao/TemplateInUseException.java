package com.jotpage.dao;

/**
 * Raised when a page_types row cannot be deleted because one or more pages
 * still reference it via foreign key. The DAO translates the underlying
 * SQLState 23000 / MySQL error 1451 into this so servlets don't have to know
 * about database-level state codes.
 */
public class TemplateInUseException extends RuntimeException {

    public TemplateInUseException(String message) {
        super(message);
    }

    public TemplateInUseException(String message, Throwable cause) {
        super(message, cause);
    }
}
