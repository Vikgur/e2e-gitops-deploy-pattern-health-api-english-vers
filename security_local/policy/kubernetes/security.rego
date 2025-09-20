package helm.security

# Running privileged containers is forbidden
deny[msg] {
  input.kind == "Pod"
  c := input.spec.containers[_]
  c.securityContext.privileged == true
  msg := sprintf("Privileged container is not allowed: %s", [c.name])
}

# Each container must define resource limits
deny[msg] {
  input.kind == "Pod"
  c := input.spec.containers[_]
  not c.resources.limits
  msg := sprintf("Missing resource limits for container: %s", [c.name])
}
