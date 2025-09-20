plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# If necessary — explicit configuration of individual rules
rule "terraform_required_providers" { enabled = true }
rule "terraform_deprecated_index"  { enabled = true }
rule "terraform_naming_convention" { enabled = true }
