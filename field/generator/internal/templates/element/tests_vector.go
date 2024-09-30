package element

const TestVector = `


import (
	"testing"
	"github.com/stretchr/testify/require"
	"sort"
	"reflect"
	"bytes"
	"os"
	"fmt"

	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/prop"
)

func TestVectorSort(t *testing.T) {
	assert := require.New(t)

	v := make(Vector, 3)
	v[0].SetUint64(2)
	v[1].SetUint64(3)
	v[2].SetUint64(1)

	sort.Sort(v)

	assert.Equal("[1,2,3]", v.String())
}

func TestVectorRoundTrip(t *testing.T) {
	assert := require.New(t)

	v1 := make(Vector, 3)
	v1[0].SetUint64(2)
	v1[1].SetUint64(3)
	v1[2].SetUint64(1)

	b, err := v1.MarshalBinary()
	assert.NoError(err)

	var v2,v3 Vector

	err = v2.UnmarshalBinary(b)
	assert.NoError(err)

	err = v3.unmarshalBinaryAsync(b)
	assert.NoError(err)

	assert.True(reflect.DeepEqual(v1,v2))
	assert.True(reflect.DeepEqual(v3,v2))
}

func TestVectorEmptyRoundTrip(t *testing.T) {
	assert := require.New(t)

	v1 := make(Vector, 0)

	b, err := v1.MarshalBinary()
	assert.NoError(err)

	var v2, v3 Vector

	err = v2.UnmarshalBinary(b)
	assert.NoError(err)

	err = v3.unmarshalBinaryAsync(b)
	assert.NoError(err)

	assert.True(reflect.DeepEqual(v1,v2))
	assert.True(reflect.DeepEqual(v3,v2))
}

func (vector *Vector) unmarshalBinaryAsync(data []byte) error {
	r := bytes.NewReader(data)
	_, err, chErr := vector.AsyncReadFrom(r)
	if err != nil {
		return err
	}
	return <-chErr
}



func TestVectorOps(t *testing.T) {
	parameters := gopter.DefaultTestParameters()
	if testing.Short() {
		parameters.MinSuccessfulTests = 2
	} else {
		parameters.MinSuccessfulTests = 10
	}
	properties := gopter.NewProperties(parameters)

	addVector := func(a, b Vector) bool {
		c := make(Vector, len(a))
		c.Add(a, b)
		
		for i := 0; i < len(a); i++ {
			var tmp {{.ElementName}}
			tmp.Add(&a[i], &b[i])
			if !tmp.Equal(&c[i]) {
				return false
			}
		}
		return true
	}

	subVector := func(a, b Vector) bool {
		c := make(Vector, len(a))
		c.Sub(a, b)
		
		for i := 0; i < len(a); i++ {
			var tmp {{.ElementName}}
			tmp.Sub(&a[i], &b[i])
			if !tmp.Equal(&c[i]) {
				return false
			}
		}
		return true
	}

	scalarMulVector := func(a Vector, b {{.ElementName}}) bool {
		c := make(Vector, len(a))
		c.ScalarMul(a, &b)
		
		for i := 0; i < len(a); i++ {
			var tmp {{.ElementName}}
			tmp.Mul(&a[i], &b)
			if !tmp.Equal(&c[i]) {
				return false
			}
		}
		return true
	}

	sumVector := func(a Vector) bool {
		var sum {{.ElementName}}
		computed := a.Sum()
		for i := 0; i < len(a); i++ {
			sum.Add(&sum, &a[i])
		}

		return sum.Equal(&computed)
	}

	innerProductVector := func(a, b Vector) bool {
		computed := a.InnerProduct(b)
		var innerProduct {{.ElementName}}
		for i := 0; i < len(a); i++ {
			var tmp {{.ElementName}}
			tmp.Mul(&a[i], &b[i])
			innerProduct.Add(&innerProduct, &tmp)
		}

		return innerProduct.Equal(&computed)
	}

	mulVector := func(a, b Vector) bool {
		c := make(Vector, len(a))
		c.Mul(a, b)
		
		for i := 0; i < len(a); i++ {
			var tmp {{.ElementName}}
			tmp.Mul(&a[i], &b[i])
			if !tmp.Equal(&c[i]) {
				return false
			}
		}
		return true
	}

	sizes := []int{1, 2, 3, 4, 509, 510, 511, 512, 513, 514}
	type genPair struct {
		g1, g2 gopter.Gen
	}
	
	for _, size := range sizes {
		generators := []genPair{
			{genZeroVector(size), genZeroVector(size)},
			{genMaxVector(size), genMaxVector(size)},
			{genVector(size), genVector(size)},
			{genVector(size), genZeroVector(size)},
		}	
		for _, gp := range generators {
			properties.Property(fmt.Sprintf("vector addition %d", size), prop.ForAll(
				addVector,
				gp.g1,
				gp.g2,
			))

			properties.Property(fmt.Sprintf("vector subtraction %d", size), prop.ForAll(
				subVector,
				gp.g1,
				gp.g2,
			))

			properties.Property(fmt.Sprintf("vector scalar multiplication %d", size), prop.ForAll(
				scalarMulVector,
				gp.g1,
				gen{{.ElementName}}(),
			))

			properties.Property(fmt.Sprintf("vector sum %d", size), prop.ForAll(
				sumVector,
				gp.g1,
			))

			properties.Property(fmt.Sprintf("vector inner product %d", size), prop.ForAll(
				innerProductVector,
				gp.g1,
				gp.g2,
			))

			properties.Property(fmt.Sprintf("vector multiplication %d", size), prop.ForAll(
				mulVector,
				gp.g1,
				gp.g2,
			))
		}
	}

	properties.TestingRun(t, gopter.NewFormatedReporter(false, 260, os.Stdout))
}


func BenchmarkVectorOps(b *testing.B) {
	// note; to benchmark against "no asm" version, use the following
	// build tag: -tags purego
	const N = 1<<24
	a1 := make(Vector, N)
	b1 := make(Vector, N)
	c1 := make(Vector, N)
	var mixer {{.ElementName}}
	mixer.SetRandom()
	for i := 1; i < N; i++ {
		a1[i-1].SetUint64(uint64(i)).
			Mul(&a1[i-1], &mixer)
		b1[i-1].SetUint64(^uint64(i)).
			Mul(&b1[i-1], &mixer)
	}

	for n:= 1<<8; n <= N; n <<= 1 {
		b.Run(fmt.Sprintf("add %d", n), func(b *testing.B) {
			_a := a1[:n]
			_b := b1[:n]
			_c := c1[:n]
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_c.Add(_a, _b)
			}
		})

		b.Run(fmt.Sprintf("sub %d", n), func(b *testing.B) {
			_a := a1[:n]
			_b := b1[:n]
			_c := c1[:n]
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_c.Sub(_a, _b)
			}
		})

		b.Run(fmt.Sprintf("scalarMul %d", n), func(b *testing.B) {
			_a := a1[:n]
			_c := c1[:n]
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_c.ScalarMul(_a, &mixer)
			}
		})

		b.Run(fmt.Sprintf("sum %d", n), func(b *testing.B) {
			_a := a1[:n]
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_ = _a.Sum()
			}
		})

		b.Run(fmt.Sprintf("innerProduct %d", n), func(b *testing.B) {
			_a := a1[:n]
			_b := b1[:n]
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				_ = _a.InnerProduct(_b)
			}
		})
	}
}

func genZeroVector(size int) gopter.Gen {
	return func(genParams *gopter.GenParameters) *gopter.GenResult {
		g := make(Vector, size)
		genResult := gopter.NewGenResult(g, gopter.NoShrinker)
		return genResult
	}
}

func genMaxVector(size int) gopter.Gen {
	return func(genParams *gopter.GenParameters) *gopter.GenResult {
		g := make(Vector, size)

		qMinusOne := qElement
		qMinusOne[0]--

		for i := 0; i < size; i++ {
			g[i] = qMinusOne
		}
		genResult := gopter.NewGenResult(g, gopter.NoShrinker)
		return genResult
	}
}

func genVector(size int) gopter.Gen {
	return func(genParams *gopter.GenParameters) *gopter.GenResult {
		g := make(Vector, size)
		mixer := {{.ElementName}}{
			{{- range $i := .NbWordsIndexesFull}}
			genParams.NextUint64(),{{end}}
		}
		if qElement[{{.NbWordsLastIndex}}] != ^uint64(0) {
			mixer[{{.NbWordsLastIndex}}] %= (qElement[{{.NbWordsLastIndex}}] +1 )
		}
		

		for !mixer.smallerThanModulus() {
			mixer = {{.ElementName}}{
				{{- range $i := .NbWordsIndexesFull}}
				genParams.NextUint64(),{{end}}
			}
			if qElement[{{.NbWordsLastIndex}}] != ^uint64(0) {
				mixer[{{.NbWordsLastIndex}}] %= (qElement[{{.NbWordsLastIndex}}] +1 )
			}
		}

		for i := 1; i <= size; i++ {
			g[i-1].SetUint64(uint64(i)).
				Mul(&g[i-1], &mixer)
		}

		genResult := gopter.NewGenResult(g, gopter.NoShrinker)
		return genResult
	}
}

`
