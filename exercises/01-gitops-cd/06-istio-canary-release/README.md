# Exercise: Troubleshoot a Failing Istio Canary Release

In this exercise, you'll troubleshoot a canary release that is being managed by Argo Rollouts but is failing to shift traffic due to an Istio misconfiguration.

## The Scenario

A new version of the `echo` service has been deployed, but the canary rollout is stuck at 10% traffic. Your task is to identify the Istio configuration issue that is preventing the rollout from proceeding and fix it.

## The Goal

*   Diagnose why the canary rollout is not progressing.
*   Identify the misconfigured Istio resource.
*   Correct the Istio configuration to allow the canary release to complete successfully.

## Useful Documentation

*   [Argo Rollouts Traffic Management with Istio](https://argo-rollouts.readthedocs.io/en/stable/traffic-management/istio/)
*   [Istio VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
*   [Istio DestinationRule](https://istio.io/latest/docs/reference/config/networking/destination-rule/)
