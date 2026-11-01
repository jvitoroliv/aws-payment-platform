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

// Rule defines the structure for a single rule within an allowlist entry
type Rule struct {
	Sources  []string `json:"sources"`
	FromPort int      `json:"from_port"`
	ToPort   int      `json:"to_port"`
	Protocol string   `json:"protocol"`
}

// AllowlistEntry defines the structure for an entry in the allowlist file
type AllowlistEntry struct {
	Description string `json:"description"`
	Rules       []Rule `json:"rules"`
}

// AllowlistFile defines the structure for the entire allowlist JSON file
type AllowlistFile map[string]AllowlistEntry

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
	byteValue, err := readJson("../../../configurations/allowlists/cidrs_blocks_by_name.json")
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

func getPrefixListsByName(t *testing.T) map[string]map[string]string {
	byteValue, err := readJson("../../../configurations/allowlists/prefix_lists_by_name.json")
	if err != nil {
		t.Fatal(err)
	}

	var prefixListsByName map[string]map[string]string
	err = json.Unmarshal(byteValue, &prefixListsByName)
	if err != nil {
		t.Fatal(err)
	}
	return prefixListsByName
}

func getAllowlistFile(t *testing.T, env string) AllowlistFile {
	var allowlist AllowlistFile
	byteValue, err := readJson("../../../configurations/allowlists/" + env + ".json")
	if err != nil {
		t.Fatal(err)
	}
	err = json.Unmarshal(byteValue, &allowlist)
	if err != nil {
		t.Fatal(err)
	}
	return allowlist
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
	prefixListsByName := getPrefixListsByName(t)

	envs := []string{"dev", "prod", "stage", "test"}
	failed := make(map[string][]string)
	for _, env := range envs {
		allowlistFile := getAllowlistFile(t, env)
		for sgName, allowlistEntry := range allowlistFile {
			for _, rule := range allowlistEntry.Rules {
				for _, sourceName := range rule.Sources {
					_, cidrOk := cidrsByName[sourceName]
					_, prefixOk := prefixListsByName[sourceName]
					if !cidrOk && !prefixOk {
						entry := fmt.Sprintf("Source '%s' in SG '%s'", sourceName, sgName)
						failed[env] = append(failed[env], entry)
					}
				}
			}
		}
	}

	assert.Equal(t, map[string][]string{}, failed, "Some sources in allowlist files were not found in cidrs_blocks_by_name.json or prefix_lists_by_name.json")
}

func TestDuplicateSourceNamesInAllowlistRules(t *testing.T) {
	envs := []string{"dev", "prod", "stage", "test"}
	var failedMessages []string

	for _, env := range envs {
		allowlistFile := getAllowlistFile(t, env)
		for sgName, allowlistEntry := range allowlistFile {
			for ruleIndex, rule := range allowlistEntry.Rules {
				sourceCount := make(map[string]int)
				for _, sourceName := range rule.Sources {
					sourceCount[sourceName]++
				}
				for sourceName, count := range sourceCount {
					if count > 1 {
						failedMessages = append(failedMessages, fmt.Sprintf("Duplicate source name '%s' found in environment '%s', security group '%s', rule #%d", sourceName, env, sgName, ruleIndex+1))
					}
				}
			}
		}
	}
	assert.Empty(t, failedMessages, "Duplicate source names found within the same rule in allowlist files.")
}

func TestPrefixListsHaveIdsForAllRegions(t *testing.T) {
	prefixListsByName := getPrefixListsByName(t)
	regions := []string{"us-east-1", "us-west-2"}
	var missingRegionIDs []string

	for prefixName, regionMap := range prefixListsByName {
		for _, region := range regions {
			id, exists := regionMap[region]
			if !exists || id == "" {
				missingRegionIDs = append(missingRegionIDs,
					fmt.Sprintf("Prefix list '%s' is missing an ID for region '%s'", prefixName, region))
			}
		}
	}

	assert.Empty(t, missingRegionIDs,
		"Some prefix lists are missing region IDs. All prefix lists must have IDs for both us-east-1 and us-west-2 regions.")
}

func TestPrefixListIdsNotReused(t *testing.T) {
	prefixListsByName := getPrefixListsByName(t)
	regions := []string{"us-east-1", "us-west-2"}

	type IDUsage struct {
		PrefixName string
		Region     string
	}

	idUsageMap := make(map[string]IDUsage)
	var duplicateIds []string

	for prefixName, regionMap := range prefixListsByName {
		for _, region := range regions {
			id, exists := regionMap[region]
			if exists && id != "" {
				if existing, found := idUsageMap[id]; found {
					duplicateIds = append(duplicateIds,
						fmt.Sprintf("Prefix list ID '%s' is reused: found in '%s' (%s) and '%s' (%s)",
							id, existing.PrefixName, existing.Region, prefixName, region))
				} else {
					idUsageMap[id] = IDUsage{
						PrefixName: prefixName,
						Region:     region,
					}
				}
			}
		}
	}

	assert.Empty(t, duplicateIds,
		"Some prefix list IDs are reused across different prefix lists or regions")
}

func TestNoDuplicateSourceNames(t *testing.T) {
	cidrsByName := getCidrByName(t)
	prefixListsByName := getPrefixListsByName(t)

	// Check for duplicate source names between CIDR blocks and prefix lists
	var duplicates []string

	for cidrName := range cidrsByName {
		if _, exists := prefixListsByName[cidrName]; exists {
			duplicates = append(duplicates, fmt.Sprintf("Source name '%s' is used in both CIDR blocks and prefix lists", cidrName))
		}
	}

	assert.Empty(t, duplicates, "Source names must be unique across CIDR blocks and prefix lists")
}
