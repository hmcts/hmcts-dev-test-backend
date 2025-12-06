package uk.gov.hmcts.reform.dev.service;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import uk.gov.hmcts.reform.dev.models.Case;
import uk.gov.hmcts.reform.dev.repository.CaseRepository;
import uk.gov.hmcts.reform.dev.services.CaseService;
import org.mockito.Mockito;

import java.util.List;
import java.time.LocalDateTime;
import java.util.UUID;

public class CaseServiceTest {

    private CaseService caseService;
    private CaseRepository mockCaseRepository;
    private Case case1;
    private Case case2;

    void setup() {
        mockCaseRepository = Mockito.mock(CaseRepository.class);
        caseService = new CaseService(mockCaseRepository);
        case1 = new Case(UUID.randomUUID(), "CASE123", "Test case 1", "OPEN", LocalDateTime.now());
        case2 = new Case(UUID.randomUUID(), "CASE456", "Test case 2", "CLOSED", LocalDateTime.now());
    }

    @Test
    void testGetAllCases() {
        setup();
        Mockito.when(mockCaseRepository.findAll()).thenReturn(List.of(case1, case2));
        List<Case> cases = caseService.getAllCases();

        assertTrue(cases.size() == 2);
        assertTrue(cases.contains(case1));
        assertTrue(cases.contains(case2));
        assertTrue(cases.get(0).getCaseNumber().equals("CASE123"));
    }

}
