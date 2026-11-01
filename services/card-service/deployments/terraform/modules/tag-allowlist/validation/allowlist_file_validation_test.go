// Package scoped to single domain responsibility
package allowlist

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Exported function — part of the service's public API contract
func readJson(filePath string) ([]byte, error) {
	jsonFile, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer jsonFile.Close()
	byteValue, _ := io.ReadAll(jsonFile)
	return byteValue, nil
}

func getCidrByName(t *testing.T) map[string][]string {
	byteValue, err := readJson("../../../configuration/allowlists/cidrs_blocks_by_name.json")
	if err != nil {
		t.Fatal(err)
	}
	var cidrsByName map[string][]string
	err = json.Unmarshal(byteValue, &cidrsByName)
	if err != nil {
		t.Fatal(err)
	}
	return cidrsByName
}

func getAllowlistFile(t *testing.T, env string) map[string][]string {
	var allowlistNames map[string][]string
	byteValue, err := readJson("../../../configuration/allowlists/" + env + ".json")
	if err != nil {
		t.Fatal(err)
	}
	err = json.Unmarshal(byteValue, &allowlistNames)
	if err != nil {
		t.Fatal(err)
	}
	return allowlistNames
}

func TestAllowlistFormat(t *testing.T) {
	cidrsByName := getCidrByName(t)
	var invalidCidrs []string
	for _, cidr := range cidrsByName {
		for _, ip := range cidr {
			_, _, err := net.ParseCIDR(ip)
			if err != nil {
				invalidCidrs = append(invalidCidrs, ip)
			}
		}
	}
	var empty []string // using []string{} creates a validation for []string{""} instead of []string(nil)
	assert.Equal(t, empty, invalidCidrs)
}

func TestAllowlistCidrBlocksHaveDuplicateIps(t *testing.T) {
	cidrsByName := getCidrByName(t)
	ipsCount := make(map[string]int)
	for _, cidr := range cidrsByName {
		for _, ip := range cidr {
			ipsCount[ip]++
		}
	}
	var duplicateIps []string
	for ip, count := range ipsCount {
		if count > 1 {
			duplicateIps = append(duplicateIps, ip)
		}
	}
	var empty []string
	assert.Equal(t, empty, duplicateIps)
}

func TestConfigurationMeetsAllowlistCidrNames(t *testing.T) {
	cidrsByName := getCidrByName(t)

	envs := []string{"dev", "prod", "stage", "test"}
	failed := make(map[string][]string)
	for _, env := range envs {
		allowlistNames := getAllowlistFile(t, env)
		for _, scope := range allowlistNames {
			for _, name := range scope {
				if _, ok := cidrsByName[name]; !ok {
					failed[env] = append(failed[env], name)
				}
			}
		}
	}

	assert.Equal(t, map[string][]string{}, failed)
}

func TestDuplicateCidrNamesInScopesForAllowlists(t *testing.T) {
	envs := []string{"dev", "prod", "stage", "test"}
	cidrNameCountByScope := make(map[string]map[string]map[string]int32)
	for _, env := range envs {
		allowlistNames := getAllowlistFile(t, env)
		cidrNameCountByScope[env] = make(map[string]map[string]int32)
		for scope, names := range allowlistNames {
			cidrNameCountByScope[env][scope] = make(map[string]int32)
			for _, name := range names {
				cidrNameCountByScope[env][scope][name]++
			}
		}
	}

	var failed []string
	for envName, env := range cidrNameCountByScope {
		for scope, names := range env {
			for name, count := range names {
				if count > 1 {
					failed = append(failed, fmt.Sprintf("Duplicate cidr name %s found in scope %s:%s", name, envName, scope))
				}
			}
		}
	}

	var empty []string
	assert.Equal(t, empty, failed)

}
