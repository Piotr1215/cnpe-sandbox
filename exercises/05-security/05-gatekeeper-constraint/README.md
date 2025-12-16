# Exercise: Create a Gatekeeper Constraint

In this exercise, you'll create a Gatekeeper `Constraint` based on a pre-existing `ConstraintTemplate` to enforce a policy that all namespaces must have a specific label.

## The Scenario

The platform team wants to ensure that all namespaces have a `team` label for cost allocation and ownership tracking. A `ConstraintTemplate` called `K8sRequiredLabels` has already been created. Your task is to create a `Constraint` that uses this template to enforce the policy.

## The Goal

*   Create a `Constraint` that requires all namespaces to have a `team` label.
*   Verify that the `Constraint` is working by attempting to create a namespace without the `team` label.

## Useful Documentation

*   [Gatekeeper Constraints](https://open-policy-agent.github.io/gatekeeper/website/docs/gator)
*   [Gatekeeper ConstraintTemplates](https://open-policy-agent.github.io/gatekeeper/website/docs/gator-v1)
