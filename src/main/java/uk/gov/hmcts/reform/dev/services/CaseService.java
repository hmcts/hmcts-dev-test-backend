package uk.gov.hmcts.reform.dev.services;

import java.util.List;

import org.springframework.stereotype.Service;

import uk.gov.hmcts.reform.dev.exception.CaseServiceException;
import uk.gov.hmcts.reform.dev.models.Case;
import uk.gov.hmcts.reform.dev.repository.CaseRepository;

@Service
public class CaseService {

    private final CaseRepository caseRepository;

    public CaseService(CaseRepository caseRepository) {
        this.caseRepository = caseRepository;
    }

    public List<Case> getAllCases() {
        try {
            return caseRepository.findAll();
        } catch (Exception e) {
            throw new CaseServiceException("Error fetching cases from database", e);
        }
    }
}
