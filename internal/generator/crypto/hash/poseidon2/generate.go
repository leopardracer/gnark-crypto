package poseidon2

import (
	"path/filepath"

	"github.com/consensys/bavard"
	"github.com/consensys/gnark-crypto/internal/generator/config"
)

func Generate(conf config.Curve, baseDir string, bgen *bavard.BatchGenerator) error {

	conf.Package = "poseidon2"
	entries := []bavard.Entry{
		// {File: filepath.Join(baseDir, "doc.go"), Templates: []string{"doc.go.tmpl"}},
		{File: filepath.Join(baseDir, "poseidon2.go"), Templates: []string{"poseidon2.go.tmpl"}},
		// {File: filepath.Join(baseDir, "options.go"), Templates: []string{"options.go.tmpl"}},
	}
	// os.Remove(filepath.Join(baseDir, "utils.go"))
	// os.Remove(filepath.Join(baseDir, "utils_test.go"))

	return bgen.Generate(conf, conf.Package, "./crypto/hash/poseidon2/template", entries...)

}
