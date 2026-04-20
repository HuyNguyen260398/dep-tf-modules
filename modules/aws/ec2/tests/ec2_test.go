package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEC2Module(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"region": "us-east-1",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	instanceID := terraform.Output(t, terraformOptions, "instance_id")
	assert.NotEmpty(t, instanceID, "instance_id output should not be empty")

	privateIP := terraform.Output(t, terraformOptions, "private_ip")
	assert.NotEmpty(t, privateIP, "private_ip output should not be empty")

	amiID := terraform.Output(t, terraformOptions, "ami_id")
	assert.NotEmpty(t, amiID, "ami_id output should not be empty")
}
