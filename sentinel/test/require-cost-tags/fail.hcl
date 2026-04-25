mock "tfplan/v2" {
  module {
    source = "../../mocks/mock-tfplan-fail.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
