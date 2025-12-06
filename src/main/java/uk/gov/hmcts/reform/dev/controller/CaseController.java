package uk.gov.hmcts.reform.dev.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import uk.gov.hmcts.reform.dev.models.Case;
import uk.gov.hmcts.reform.dev.service.CaseService;

import java.util.List;

@RestController
@RequestMapping("/api")
public class CaseController {

    private final CaseService caseService;

    public CaseController(CaseService caseService) {
        this.caseService = caseService;
    }

    @GetMapping("/cases")
    public List<Case> getAllCases() {
        return caseService.getAllCases();
    }
}