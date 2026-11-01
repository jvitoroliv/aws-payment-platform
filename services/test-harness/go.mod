module ps-tag-test-harness

go 1.15

require (
	github.com/dchest/uniuri v0.0.0-20200228104902-7aecb25e1fe5
	github.com/go-playground/universal-translator v0.17.0 // indirect
	github.com/google/uuid v1.2.0 // indirect
	github.com/gorilla/mux v1.8.0
	github.com/gorilla/sessions v1.2.1
	github.com/kr/pretty v0.2.0 // indirect
	github.com/leekchan/accounting v1.0.0 // indirect
	github.com/microcosm-cc/bluemonday v1.0.4 // indirect
	github.com/pborman/uuid v1.2.1 // indirect
	github.com/pkg/sftp v1.12.0 // indirect
	github.com/stretchr/testify v1.7.0
	github.com/tealeg/xlsx v1.0.5
	golang.org/x/crypto v0.0.0-20210220033148-5ea612d1eb83
	gopkg.in/gomail.v2 v2.0.0-20160411212932-81ebce5c23df // indirect
	gopkg.in/yaml.v3 v3.0.0-20200615113413-eeeca48fe776 // indirect
	tag-mock-service-dev v0.165.6-0.20220428153148-9083787afa34
)

replace tag-mock-service-dev => github.com/example-org/ps-tag-dev v0.168.2-0.20220606210739-70d27d2ce5e0
