// Copyright 2020 ConsenSys Software Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Code generated by consensys/gnark-crypto DO NOT EDIT

package bls12381

import (
	"fmt"
	"math/big"
	"testing"

	"github.com/consensys/gnark-crypto/ecc/bls12-381/fp"
	"github.com/consensys/gnark-crypto/ecc/bls12-381/fr"
	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/prop"
)

// ------------------------------------------------------------
// tests

func TestPairing(t *testing.T) {

	t.Parallel()
	parameters := gopter.DefaultTestParameters()
	if testing.Short() {
		parameters.MinSuccessfulTests = nbFuzzShort
	} else {
		parameters.MinSuccessfulTests = nbFuzz
	}

	properties := gopter.NewProperties(parameters)

	genA := GenE12()
	genR1 := GenFr()
	genR2 := GenFr()
	genP := GenFp()

	properties.Property("[BLS12-381] Having the receiver as operand (final expo) should output the same result", prop.ForAll(
		func(a GT) bool {
			b := a
			b = FinalExponentiation(&a)
			a = FinalExponentiation(&a)
			return a.Equal(&b)
		},
		genA,
	))

	properties.Property("[BLS12-381] Exponentiating FinalExpo(a) to r should output 1", prop.ForAll(
		func(a GT) bool {
			b := FinalExponentiation(&a)
			return !a.IsInSubGroup() && b.IsInSubGroup()
		},
		genA,
	))

	properties.Property("[BLS12-381] Exp, CyclotomicExp and ExpGLV results must be the same in GT", prop.ForAll(
		func(a GT, e fp.Element) bool {
			a = FinalExponentiation(&a)

			var _e big.Int

			k := new(big.Int).SetUint64(12)
			e.Exp(e, k)
			e.ToBigIntRegular(&_e)

			var b, c, d GT
			b.Exp(a, &_e)
			c.ExpGLV(a, &_e)
			d.CyclotomicExp(a, &_e)

			return b.Equal(&c) && c.Equal(&d)
		},
		genA,
		genP,
	))

	properties.Property("[BLS12-381] Expt(Expt) and Exp(t^2) should output the same result in the cyclotomic subgroup", prop.ForAll(
		func(a GT) bool {
			var b, c, d GT
			b.Conjugate(&a)
			a.Inverse(&a)
			b.Mul(&b, &a)

			a.FrobeniusSquare(&b).
				Mul(&a, &b)

			c.Expt(&a).Expt(&c)
			d.Exp(a, &xGen).Exp(d, &xGen)
			return c.Equal(&d)
		},
		genA,
	))

	properties.Property("[BLS12-381] bilinearity", prop.ForAll(
		func(a, b fr.Element) bool {

			var res, resa, resb, resab, zero GT

			var ag1 G1Affine
			var bg2 G2Affine

			var abigint, bbigint, ab big.Int

			a.ToBigIntRegular(&abigint)
			b.ToBigIntRegular(&bbigint)
			ab.Mul(&abigint, &bbigint)

			ag1.ScalarMultiplication(&g1GenAff, &abigint)
			bg2.ScalarMultiplication(&g2GenAff, &bbigint)

			res, _ = Pair([]G1Affine{g1GenAff}, []G2Affine{g2GenAff})
			resa, _ = Pair([]G1Affine{ag1}, []G2Affine{g2GenAff})
			resb, _ = Pair([]G1Affine{g1GenAff}, []G2Affine{bg2})

			resab.Exp(res, &ab)
			resa.Exp(resa, &bbigint)
			resb.Exp(resb, &abigint)

			return resab.Equal(&resa) && resab.Equal(&resb) && !res.Equal(&zero)

		},
		genR1,
		genR2,
	))

	properties.Property("[BLS12-381] PairingCheck", prop.ForAll(
		func(a, b fr.Element) bool {

			var g1GenAffNeg G1Affine
			g1GenAffNeg.Neg(&g1GenAff)
			tabP := []G1Affine{g1GenAff, g1GenAffNeg}
			tabQ := []G2Affine{g2GenAff, g2GenAff}

			res, _ := PairingCheck(tabP, tabQ)

			return res
		},
		genR1,
		genR2,
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

func TestMillerLoop(t *testing.T) {

	t.Parallel()
	parameters := gopter.DefaultTestParameters()
	if testing.Short() {
		parameters.MinSuccessfulTests = nbFuzzShort
	} else {
		parameters.MinSuccessfulTests = nbFuzz
	}

	properties := gopter.NewProperties(parameters)

	genR1 := GenFr()
	genR2 := GenFr()

	properties.Property("[BLS12-381] MillerLoop of pairs should be equal to the product of MillerLoops", prop.ForAll(
		func(a, b fr.Element) bool {

			var simpleProd, factorizedProd GT

			var ag1 G1Affine
			var bg2 G2Affine

			var abigint, bbigint big.Int

			a.ToBigIntRegular(&abigint)
			b.ToBigIntRegular(&bbigint)

			ag1.ScalarMultiplication(&g1GenAff, &abigint)
			bg2.ScalarMultiplication(&g2GenAff, &bbigint)

			P0 := []G1Affine{g1GenAff}
			P1 := []G1Affine{ag1}
			Q0 := []G2Affine{g2GenAff}
			Q1 := []G2Affine{bg2}

			// FE( ML(a,b) * ML(c,d) * ML(e,f) * ML(g,h) )
			M1, _ := MillerLoop(P0, Q0)
			M2, _ := MillerLoop(P1, Q0)
			M3, _ := MillerLoop(P0, Q1)
			M4, _ := MillerLoop(P1, Q1)
			simpleProd.Mul(&M1, &M2).Mul(&simpleProd, &M3).Mul(&simpleProd, &M4)
			simpleProd = FinalExponentiation(&simpleProd)

			tabP := []G1Affine{g1GenAff, ag1, g1GenAff, ag1}
			tabQ := []G2Affine{g2GenAff, g2GenAff, bg2, bg2}

			// FE( ML([a,c,e,g] ; [b,d,f,h]) ) -> saves 3 squares in Fqk
			factorizedProd, _ = Pair(tabP, tabQ)

			return simpleProd.Equal(&factorizedProd)
		},
		genR1,
		genR2,
	))

	properties.Property("[BLS12-381] MillerLoop should skip pairs with a point at infinity", prop.ForAll(
		func(a, b fr.Element) bool {

			var one GT

			var ag1, g1Inf G1Affine
			var bg2, g2Inf G2Affine

			var abigint, bbigint big.Int

			one.SetOne()

			a.ToBigIntRegular(&abigint)
			b.ToBigIntRegular(&bbigint)

			ag1.ScalarMultiplication(&g1GenAff, &abigint)
			bg2.ScalarMultiplication(&g2GenAff, &bbigint)

			g1Inf.FromJacobian(&g1Infinity)
			g2Inf.FromJacobian(&g2Infinity)

			// e([0,c] ; [b,d])
			tabP := []G1Affine{g1Inf, ag1}
			tabQ := []G2Affine{g2GenAff, bg2}
			res1, _ := Pair(tabP, tabQ)

			// e([a,c] ; [0,d])
			tabP = []G1Affine{g1GenAff, ag1}
			tabQ = []G2Affine{g2Inf, bg2}
			res2, _ := Pair(tabP, tabQ)

			// e([0,c] ; [d,0])
			tabP = []G1Affine{g1Inf, ag1}
			tabQ = []G2Affine{bg2, g2Inf}
			res3, _ := Pair(tabP, tabQ)

			return res1.Equal(&res2) && !res2.Equal(&res3) && res3.Equal(&one)
		},
		genR1,
		genR2,
	))

	properties.Property("[BLS12-381] compressed pairing", prop.ForAll(
		func(a, b fr.Element) bool {

			var ag1 G1Affine
			var bg2 G2Affine

			var abigint, bbigint big.Int

			a.ToBigIntRegular(&abigint)
			b.ToBigIntRegular(&bbigint)

			ag1.ScalarMultiplication(&g1GenAff, &abigint)
			bg2.ScalarMultiplication(&g2GenAff, &bbigint)

			res, _ := Pair([]G1Affine{ag1}, []G2Affine{bg2})

			compressed, _ := res.CompressTorus()
			decompressed := compressed.DecompressTorus()

			return decompressed.Equal(&res)

		},
		genR1,
		genR2,
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// ------------------------------------------------------------
// benches

func BenchmarkPairing(b *testing.B) {

	var g1GenAff G1Affine
	var g2GenAff G2Affine

	g1GenAff.FromJacobian(&g1Gen)
	g2GenAff.FromJacobian(&g2Gen)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		Pair([]G1Affine{g1GenAff}, []G2Affine{g2GenAff})
	}
}

func BenchmarkMillerLoop(b *testing.B) {

	var g1GenAff G1Affine
	var g2GenAff G2Affine

	g1GenAff.FromJacobian(&g1Gen)
	g2GenAff.FromJacobian(&g2Gen)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		MillerLoop([]G1Affine{g1GenAff}, []G2Affine{g2GenAff})
	}
}

func BenchmarkFinalExponentiation(b *testing.B) {

	var a GT
	a.SetRandom()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		FinalExponentiation(&a)
	}

}

func BenchmarkMultiMiller(b *testing.B) {

	var g1GenAff G1Affine
	var g2GenAff G2Affine

	g1GenAff.FromJacobian(&g1Gen)
	g2GenAff.FromJacobian(&g2Gen)

	n := 10
	P := make([]G1Affine, n)
	Q := make([]G2Affine, n)

	for i := 2; i <= n; i++ {
		for j := 0; j < i; j++ {
			P[j].Set(&g1GenAff)
			Q[j].Set(&g2GenAff)
		}
		b.Run(fmt.Sprintf("%d pairs", i), func(b *testing.B) {
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				MillerLoop(P, Q)
			}
		})
	}
}

func BenchmarkMultiPair(b *testing.B) {

	var g1GenAff G1Affine
	var g2GenAff G2Affine

	g1GenAff.FromJacobian(&g1Gen)
	g2GenAff.FromJacobian(&g2Gen)

	n := 10
	P := make([]G1Affine, n)
	Q := make([]G2Affine, n)

	for i := 2; i <= n; i++ {
		for j := 0; j < i; j++ {
			P[j].Set(&g1GenAff)
			Q[j].Set(&g2GenAff)
		}
		b.Run(fmt.Sprintf("%d pairs", i), func(b *testing.B) {
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				Pair(P, Q)
			}
		})
	}
}

func BenchmarkExpGT(b *testing.B) {

	var a GT
	a.SetRandom()
	a = FinalExponentiation(&a)

	var e fp.Element
	e.SetRandom()

	k := new(big.Int).SetUint64(12)
	e.Exp(e, k)
	var _e big.Int
	e.ToBigIntRegular(&_e)

	b.Run("Naive windowed Exp", func(b *testing.B) {
		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			a.Exp(a, &_e)
		}
	})

	b.Run("2-NAF cyclotomic Exp", func(b *testing.B) {
		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			a.CyclotomicExp(a, &_e)
		}
	})

	b.Run("windowed 2-dim GLV Exp", func(b *testing.B) {
		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			a.ExpGLV(a, &_e)
		}
	})
}
