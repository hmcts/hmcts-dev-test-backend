package uk.gov.hmcts.reform.dev.service;

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

    public Case createCase(Case caseRequest) {
        if (caseRepository.existsByCaseNumber(caseRequest.getCaseNumber())) {
            throw new CaseServiceException("Case with case number '" + caseRequest.getCaseNumber() + "' already exists",
                    null);
        }
        try {
            return caseRepository.save(caseRequest);
        } catch (Exception e) {
            throw new CaseServiceException("Error creating new case", e);
        }
    }
}
