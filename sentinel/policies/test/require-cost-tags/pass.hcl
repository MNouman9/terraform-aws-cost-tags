mock "tfplan/v2" {
  module {
    source = "../../../mocks/mock-tfplan-pass.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
