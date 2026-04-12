package com.jotpage.model;

import java.sql.Timestamp;

public class PageType {

    private long id;
    private Long userId;
    private String name;
    private String backgroundType;
    private String backgroundData;
    private boolean immutableOnClose;
    private boolean system;
    private Timestamp createdAt;

    public PageType() {
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getBackgroundType() {
        return backgroundType;
    }

    public void setBackgroundType(String backgroundType) {
        this.backgroundType = backgroundType;
    }

    public String getBackgroundData() {
        return backgroundData;
    }

    public void setBackgroundData(String backgroundData) {
        this.backgroundData = backgroundData;
    }

    public boolean isImmutableOnClose() {
        return immutableOnClose;
    }

    public void setImmutableOnClose(boolean immutableOnClose) {
        this.immutableOnClose = immutableOnClose;
    }

    public boolean isSystem() {
        return system;
    }

    public void setSystem(boolean system) {
        this.system = system;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
