"""PRESENT-80 reference model.

Bogdanov et al., "PRESENT: An Ultra-Lightweight Block Cipher", CHES 2007.
Bits are numbered from 0, with bit 0 on the right (least significant), as in the paper.
"""

SBOX = [0xC, 0x5, 0x6, 0xB, 0x9, 0x0, 0xA, 0xD,
        0x3, 0xE, 0xF, 0x8, 0x4, 0x7, 0x1, 0x2]

MASK64 = (1 << 64) - 1
MASK80 = (1 << 80) - 1
NUM_ROUNDS = 31


def add_round_key(state: int, key: int) -> int:
    """XOR the state with the round key: the top 64 bits (k79..k16) of the key register."""
    round_key = key >> 16
    return state ^ round_key


def sbox_layer(state: int) -> int:
    """Apply the S-box to each of the 16 nibbles of the state."""
    result = 0
    for i in range(16):
        nibble = (state >> (4 * i)) & 0xF
        result |= SBOX[nibble] << (4 * i)
    return result


def p_position(i: int) -> int:
    """Where bit i moves to under the permutation."""
    if i == 63:
        return 63
    return (16 * i) % 63


def p_layer(state: int) -> int:
    """Move every bit i of the state to position p_position(i)."""
    result = 0
    for i in range(64):
        bit = (state >> i) & 1
        result |= bit << p_position(i)
    return result


def update_key(key: int, round_counter: int) -> int:
    """Compute the next key register value (paper, Section 3, key schedule)."""
    # 1. Rotate the 80-bit register left by 61.
    key = ((key << 61) | (key >> 19)) & MASK80
    # 2. Pass the top nibble (k79..k76) through the S-box.
    top = key >> 76
    key = (key & ((1 << 76) - 1)) | (SBOX[top] << 76)
    # 3. XOR the round counter into k19..k15 (counter's LSB at k15).
    key ^= round_counter << 15
    return key


def encrypt(plaintext: int, key: int) -> int:
    """Encrypt one 64-bit block with an 80-bit key."""
    state = plaintext & MASK64
    key = key & MASK80
    for round_counter in range(1, NUM_ROUNDS + 1):
        state = add_round_key(state, key)
        state = sbox_layer(state)
        state = p_layer(state)
        key = update_key(key, round_counter)
    state = add_round_key(state, key)  # final key addition with K32
    return state


if __name__ == "__main__":
    # Official test vectors, Appendix I of the paper.
    vectors = [
        (0x0000000000000000, 0x00000000000000000000, 0x5579C1387B228445),
        (0x0000000000000000, 0xFFFFFFFFFFFFFFFFFFFF, 0xE72C46C0F5945049),
        (0xFFFFFFFFFFFFFFFF, 0x00000000000000000000, 0xA112FFC72F68417B),
        (0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFFFFFF, 0x3333DCD3213210D2),
    ]
    for pt, k, expected in vectors:
        got = encrypt(pt, k)
        status = "PASS" if got == expected else "FAIL"
        print(f"{status}  pt={pt:016X}  key={k:020X}  ct={got:016X}")