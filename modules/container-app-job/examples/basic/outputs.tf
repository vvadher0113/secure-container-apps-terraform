output "job_id" {
  description = "Resource ID of the container app job."
  value       = module.migrate_job.id
}

output "job_name" {
  description = "Name of the container app job."
  value       = module.migrate_job.name
}
