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

package fft

import (
	"math/bits"

	"github.com/consensys/gnark-crypto/ecc/bls24-317/fr"
)

// BitReverse applies the bit-reversal permutation to a.
// len(a) must be a power of 2 (as in every single function in this file)
func BitReverse(a []fr.Element) {
	n := uint64(len(a))
	nn := uint64(64 - bits.TrailingZeros64(n))

	for i := uint64(0); i < n; i++ {
		irev := bits.Reverse64(i) >> nn
		if irev > i {
			a[i], a[irev] = a[irev], a[i]
		}
	}
}

func deriveLogTileSize(logN uint64) uint64 {
	q := uint64(9)

	for int(logN)-int(2*q) <= 0 {
		q--
	}

	return q
}

func BitReverseCobraInPlace(buf []fr.Element) {
	logN := uint64(bits.Len64(uint64(len(buf))) - 1)
	logTileSize := deriveLogTileSize(logN)
	logBLen := logN - 2*logTileSize
	bLen := uint64(1) << logBLen
	tileSize := uint64(1) << logTileSize

	t := make([]fr.Element, tileSize*tileSize)

	for b := uint64(0); b < bLen; b++ {
		bRev := bits.Reverse64(b) >> (64 - logBLen)

		for a := uint64(0); a < tileSize; a++ {
			aRev := bits.Reverse64(a) >> (64 - logTileSize)
			for c := uint64(0); c < tileSize; c++ {
				tIdx := (aRev << logTileSize) | c
				idx := (a << (logBLen + logTileSize)) | (b << logTileSize) | c
				t[tIdx] = buf[idx]
			}
		}

		for c := uint64(0); c < tileSize; c++ {
			cRev := bits.Reverse64(c) >> (64 - logTileSize)
			for aRev := uint64(0); aRev < tileSize; aRev++ {
				a := bits.Reverse64(aRev) >> (64 - logTileSize)
				idx := (a << (logBLen + logTileSize)) | (b << logTileSize) | c
				idxRev := (cRev << (logBLen + logTileSize)) | (bRev << logTileSize) | aRev
				if idx < idxRev {
					tIdx := (aRev << logTileSize) | c
					buf[idxRev], t[tIdx] = t[tIdx], buf[idxRev]
				}
			}
		}

		for a := uint64(0); a < tileSize; a++ {
			aRev := bits.Reverse64(a) >> (64 - logTileSize)
			for c := uint64(0); c < tileSize; c++ {
				cRev := bits.Reverse64(c) >> (64 - logTileSize)
				idx := (a << (logBLen + logTileSize)) | (b << logTileSize) | c
				idxRev := (cRev << (logBLen + logTileSize)) | (bRev << logTileSize) | aRev
				if idx < idxRev {
					tIdx := (aRev << logTileSize) | c
					buf[idx], t[tIdx] = t[tIdx], buf[idx]
				}
			}
		}
	}
}
