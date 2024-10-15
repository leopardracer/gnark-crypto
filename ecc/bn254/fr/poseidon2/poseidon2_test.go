// Copyright 2020 Consensys Software Inc.
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

package poseidon2

import (
	"testing"

	"github.com/consensys/gnark-crypto/ecc/bn254/fr"
)

func TestExternalMatrix(t *testing.T) {

	var expected [4][4]fr.Element
	expected[0][0].SetUint64(5)
	expected[0][1].SetUint64(4)
	expected[0][2].SetUint64(1)
	expected[0][3].SetUint64(1)

	expected[1][0].SetUint64(7)
	expected[1][1].SetUint64(6)
	expected[1][2].SetUint64(3)
	expected[1][3].SetUint64(1)

	expected[2][0].SetUint64(1)
	expected[2][1].SetUint64(1)
	expected[2][2].SetUint64(5)
	expected[2][3].SetUint64(4)

	expected[3][0].SetUint64(3)
	expected[3][1].SetUint64(1)
	expected[3][2].SetUint64(7)
	expected[3][3].SetUint64(6)

	h := NewHash(4, 5, 9, 56, "seed")
	var tmp [4]fr.Element
	for i := 0; i < 4; i++ {
		for j := 0; j < 4; j++ {
			tmp[j].SetUint64(0)
			if i == j {
				tmp[j].SetOne()
			}
		}
		// h.Write(tmp[:])
		h.matMulExternalInPlace(tmp[:])
		for j := 0; j < 4; j++ {
			if !tmp[j].Equal(&expected[i][j]) {
				t.Fatal("error matMul4")
			}
		}
	}

}
