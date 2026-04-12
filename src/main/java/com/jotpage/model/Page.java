package com.jotpage.model;

import java.sql.Timestamp;

public class Page {

    private long id;
    private long userId;
    private long pageTypeId;
    private String title;
    private int sortOrder;
    private String inkData;
    private String textLayers;
    private boolean closed;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public Page() {
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getUserId() {
        return userId;
    }

    public void setUserId(long userId) {
        this.userId = userId;
    }

    public long getPageTypeId() {
        return pageTypeId;
    }

    public void setPageTypeId(long pageTypeId) {
        this.pageTypeId = pageTypeId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }

    public String getInkData() {
        return inkData;
    }

    public void setInkData(String inkData) {
        this.inkData = inkData;
    }

    public String getTextLayers() {
        return textLayers;
    }

    public void setTextLayers(String textLayers) {
        this.textLayers = textLayers;
    }

    public boolean isClosed() {
        return closed;
    }

    public void setClosed(boolean closed) {
        this.closed = closed;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
}
