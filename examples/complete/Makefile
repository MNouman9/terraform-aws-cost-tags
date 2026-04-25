SENTINEL_POLICY := ../../sentinel/policies/require-cost-tags.sentinel
SENTINEL_CONFIG := ../../sentinel/sentinel.hcl

.PHONY: lint validate plan sentinel test

lint:
	terraform fmt -check -recursive ../..

validate:
	terraform validate

plan:
	terraform plan -out=tfplan.binary
	terraform show -json tfplan.binary > tfplan.json

sentinel: plan
	sentinel apply -config=$(SENTINEL_CONFIG) $(SENTINEL_POLICY)

test:
	sentinel test $(SENTINEL_POLICY)

clean:
	rm -f tfplan.binary tfplan.json
