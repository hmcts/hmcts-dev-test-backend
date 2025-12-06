package uk.gov.hmcts.reform.dev.repository;

import org.springframework.data.repository.ListCrudRepository;
import uk.gov.hmcts.reform.dev.models.Case;
import java.util.UUID;

public interface CaseRepository extends ListCrudRepository<Case, UUID> {

  
}
