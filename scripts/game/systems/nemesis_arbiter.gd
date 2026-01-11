class_name NemesisArbiter
extends RefCounted

## Conflict resolution and execution orchestrator
## Completely agnostic of events and specific traits

var pending_requests: Array = []
var processing_scheduled: bool = false

## Called by traits to request execution
## Batches all requests in the same frame
func request_execution(trait_request) -> void:
	pending_requests.append(trait_request)

	# Schedule processing only once per frame
	if not processing_scheduled:
		processing_scheduled = true
		# Use call_deferred to wait until end of frame
		# This ensures all traits that trigger in the same frame are processed together
		var callable = Callable(self, "_process_requests")
		callable.call_deferred()

## Process all collected requests at end of frame
func _process_requests() -> void:
	processing_scheduled = false

	if pending_requests.is_empty():
		return

	# Sort by priority (descending)
	pending_requests.sort_custom(func(a, b): return a.priority > b.priority)

	# Build execution list based on parallel compatibility
	var execution_list: Array = []

	for request in pending_requests:
		if execution_list.is_empty():
			# Always add highest priority request
			execution_list.append(request)
		else:
			# Check if we can add this request
			var can_add = true

			for existing in execution_list:
				# If any existing request is non-parallel, stop adding
				if not existing.can_execute_parallel:
					can_add = false
					break
				# If this request is non-parallel, it can't be added alongside others
				if not request.can_execute_parallel:
					can_add = false
					break

			if can_add:
				execution_list.append(request)
			else:
				# Stop processing - non-parallel request blocks further execution
				break

	# Execute all requests in the execution list
	for request in execution_list:
		if request.nemesis_trait:
			request.nemesis_trait.execute(request.context)

	# Clear the queue
	pending_requests.clear()
