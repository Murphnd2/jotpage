package com.jotpage.model;

import java.sql.Timestamp;

public class UsageRecord {

    private long id;
    private long userId;
    private String monthYear;
    private int pagesCreated;
    private int aiJobsRun;
    private double audioMinutesProcessed;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public UsageRecord() {
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

    public String getMonthYear() {
        return monthYear;
    }

    public void setMonthYear(String monthYear) {
        this.monthYear = monthYear;
    }

    public int getPagesCreated() {
        return pagesCreated;
    }

    public void setPagesCreated(int pagesCreated) {
        this.pagesCreated = pagesCreated;
    }

    public int getAiJobsRun() {
        return aiJobsRun;
    }

    public void setAiJobsRun(int aiJobsRun) {
        this.aiJobsRun = aiJobsRun;
    }

    public double getAudioMinutesProcessed() {
        return audioMinutesProcessed;
    }

    public void setAudioMinutesProcessed(double audioMinutesProcessed) {
        this.audioMinutesProcessed = audioMinutesProcessed;
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
