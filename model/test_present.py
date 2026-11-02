"""Tests for the PRESENT-80 reference model.

Run with:  pytest -v
"""

import pytest

from present import (
    SBOX,
    add_round_key,
    encrypt,
    p_layer,
    p_position,
    sbox_layer,
    update_key,
)

# --------------------------------------------------------------------------
# S-box
# --------------------------------------------------------------------------

def test_sbox_is_a_permutation():
    # Every output appears exactly once, so the S-box can be reversed.
    assert sorted(SBOX) == list(range(16))


def test_sbox_layer_worked_example():
    # 5 0 9 E -> 0 C E 1 (the hand exercise). The top 12 nibbles are 0,
    # and S[0] = C, so each of them becomes C.
    assert sbox_layer(0x000000000000509E) == 0xCCCCCCCCCCCC0CE1


def test_sbox_layer_all_zeros():
    assert sbox_layer(0) == 0xCCCCCCCCCCCCCCCC


def test_sbox_layer_each_nibble_independently():
    # Put every possible value into every nibble position, one at a time.
    for position in range(16):
        for value in range(16):
            state = value << (4 * position)
            out = sbox_layer(state)
            assert (out >> (4 * position)) & 0xF == SBOX[value]


# --------------------------------------------------------------------------
# Permutation layer
# --------------------------------------------------------------------------

# P(i) table copied from Section 3 ("pLayer") of the paper.
P_TABLE = [
     0, 16, 32, 48,  1, 17, 33, 49,  2, 18, 34, 50,  3, 19, 35, 51,
     4, 20, 36, 52,  5, 21, 37, 53,  6, 22, 38, 54,  7, 23, 39, 55,
     8, 24, 40, 56,  9, 25, 41, 57, 10, 26, 42, 58, 11, 27, 43, 59,
    12, 28, 44, 60, 13, 29, 45, 61, 14, 30, 46, 62, 15, 31, 47, 63,
]


def test_p_position_matches_paper_table():
    for i in range(64):
        assert p_position(i) == P_TABLE[i], f"bit {i}"


def test_p_layer_is_a_permutation():
    assert sorted(p_position(i) for i in range(64)) == list(range(64))


def test_p_layer_moves_each_single_bit():
    # A state with only bit i set must come out with only bit P(i) set.
    for i in range(64):
        assert p_layer(1 << i) == 1 << P_TABLE[i], f"bit {i}"


# --------------------------------------------------------------------------
# Round key and key schedule
# --------------------------------------------------------------------------

def test_add_round_key_uses_top_64_bits():
    # Only the bottom 16 key bits set: they are not part of the round key.
    assert add_round_key(0x0, 0xFFFF) == 0x0
    # Only the top 64 key bits set: the round key is all ones.
    assert add_round_key(0x0, 0xFFFFFFFFFFFFFFFF << 16) == 0xFFFFFFFFFFFFFFFF


def test_update_key_from_zero_key():
    # Rotating zero gives zero; the top nibble 0 becomes S[0] = C;
    # round counter 1 is XORed in at bit 15.
    assert update_key(0, 1) == (0xC << 76) | (1 << 15)


def test_update_key_stays_80_bits():
    key = (1 << 80) - 1
    for r in range(1, 32):
        key = update_key(key, r)
        assert key < (1 << 80)


# --------------------------------------------------------------------------
# Full cipher: official test vectors, Appendix I of the paper
# --------------------------------------------------------------------------

VECTORS = [
    # (plaintext,           key,                    ciphertext)
    (0x0000000000000000, 0x00000000000000000000, 0x5579C1387B228445),
    (0x0000000000000000, 0xFFFFFFFFFFFFFFFFFFFF, 0xE72C46C0F5945049),
    (0xFFFFFFFFFFFFFFFF, 0x00000000000000000000, 0xA112FFC72F68417B),
    (0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFFFFFF, 0x3333DCD3213210D2),
]


@pytest.mark.parametrize("plaintext,key,ciphertext", VECTORS)
def test_official_vectors(plaintext, key, ciphertext):
    assert encrypt(plaintext, key) == ciphertext