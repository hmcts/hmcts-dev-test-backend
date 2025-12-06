package uk.gov.hmcts.reform.dev.exception;

public class CaseServiceException extends RuntimeException {
    
    public CaseServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}
