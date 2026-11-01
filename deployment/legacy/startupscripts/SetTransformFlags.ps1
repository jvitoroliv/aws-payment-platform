# If environment variables does not contain AWS, add it.
if ($env:TRANSFORM_FLAGS) {
	if (($env:TRANSFORM_FLAGS -split ",") -notcontains "AWS") {
		$env:TRANSFORM_FLAGS = "AWS" + "," + $env:TRANSFORM_FLAGS
	}
}
else {
	$env:TRANSFORM_FLAGS = "AWS"
}