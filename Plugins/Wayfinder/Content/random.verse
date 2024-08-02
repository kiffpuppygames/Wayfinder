seedable_random<public> := module:
    LeftShift(Value : int, Shift : int)<transacts><decides>:int=
        var Output : int = 0

        for (Index := 0..(31 - Shift)):
            Shifted := RightShift[Value, Index]

            Bit := Mod[Shifted, 2]

            if (Bit = 1):
                set Output += Floor[Pow(2.0, (Index + Shift) * 1.0)]

        return Output

    RightShift(Value : int, Shift : int)<transacts><decides>:int=
        return Floor[(Value * 1.0) / (Pow(2.0, Shift * 1.0))]

    XOR(A : int, B : int)<transacts><decides>:int=
        var Output : int = 0

        var ShiftedA : int = A
        var ShiftedB : int = B

        for (Index := 0..63, ShiftedA <> 0 or ShiftedB <> 0):
            BitA := Mod[ShiftedA, 2]
            BitB := Mod[ShiftedB, 2]

            if ((BitA = 1 and BitB = 0) or (BitA = 0 and BitB = 1)):
                _output := Output + LeftShift[1, Index]
                set Output = _output

            _shiftedA := RightShift[ShiftedA, 1]
            set ShiftedA = _shiftedA
            _shiftedB := RightShift[ShiftedB, 1]
            set ShiftedB = _shiftedB

        return Output

    OR(A : int, B : int)<transacts><decides>:int=
        var Output : int = 0

        var ShiftedA : int = A
        var ShiftedB : int = B

        for (Index := 0..63, ShiftedA <> 0 or ShiftedB <> 0):
            BitA := Mod[ShiftedA, 2]
            BitB := Mod[ShiftedB, 2]

            if (BitA = 1 or BitB = 1):
                _output := Output + LeftShift[1, Index]
                set Output = _output

            _shiftedA := RightShift[ShiftedA, 1]
            set ShiftedA = _shiftedA
            _shiftedB := RightShift[ShiftedB, 1]
            set ShiftedB = _shiftedB

        return Output

    UInt32(Value : int)<transacts><decides>:int=
        var Output : int = 0

        if (Value > 4294967295):
            for (Index := 0..31):
                Shifted := RightShift[Value, Index]

                Bit := Mod[Shifted, 2]

                if (Bit = 1):
                    set Output += LeftShift[1, Index]
        else if (Value < 0):
            for (Index := 0..31):
                Shifted := RightShift[-Value, Index]
        
                Bit := Mod[Shifted, 2]
        
                if (Bit = 0):
                    set Output += LeftShift[1, Index]
        
            set Output += 1
        else:
            set Output = Value

        return Output

    UInt16(Value : int)<transacts><decides>:int=
        var Output : int = 0

        if (Value > 65535):
            for (Index := 0..15):
                Shifted := RightShift[Value, Index]

                Bit := Mod[Shifted, 2]

                if (Bit = 1):
                    set Output += LeftShift[1, Index]
        else if (Value < 0):
            for (Index := 0..15):
                Shifted := RightShift[-Value, Index]
        
                Bit := Mod[Shifted, 2]
        
                if (Bit = 0):
                    set Output += LeftShift[1, Index]
        
            set Output += 1
        else:
            set Output = Value

        return Output

    Int32(Value : int)<transacts><decides>:int=
        var Output : int = 0

        if (Value > 2147483647):
            TopBit := Mod[RightShift[Value, 31], 2]

            set Output = -LeftShift[TopBit, 31]

            for (Index := 0..30):
                Shifted := RightShift[Value, Index]

                Bit := Mod[Shifted, 2]

                if (Bit = 1):
                    set Output += LeftShift[1, Index]
        else:
            set Output = Value

        return Output

    IMul(A : int, B : int)<transacts><decides>:int=
        CastA := UInt32[A]
        CastB := UInt32[B]

        HighA := UInt16[RightShift[CastA, 16]]
        LowA := UInt16[CastA]

        HighB := UInt16[RightShift[CastB, 16]]
        LowB := UInt16[CastB]

        return Int32[LowA * LowB + UInt32[LeftShift[HighA * LowB + LowA * HighB, 16]]]

    CharCodes : [char]int = map{
        '\t' => 9,
        '\n' => 10,
        '\r' => 13,
        ' ' => 32,
        '!' => 33,
        '"' => 34,
        '#' => 35,
        '$' => 36,
        '%' => 37,
        '&' => 38,
        '\'' => 39,
        '(' => 40,
        ')' => 41,
        '*' => 42,
        '+' => 43,
        ',' => 44,
        '-' => 45,
        '.' => 46,
        '/' => 47,
        '0' => 48,
        '1' => 49,
        '2' => 50,
        '3' => 51,
        '4' => 52,
        '5' => 53,
        '6' => 54,
        '7' => 55,
        '8' => 56,
        '9' => 57,
        ':' => 58,
        ';' => 59,
        '<' => 60,
        '=' => 61,
        '>' => 62,
        '?' => 63,
        '@' => 64,
        'A' => 65,
        'B' => 66,
        'C' => 67,
        'D' => 68,
        'E' => 69,
        'F' => 70,
        'G' => 71,
        'H' => 72,
        'I' => 73,
        'J' => 74,
        'K' => 75,
        'L' => 76,
        'M' => 77,
        'N' => 78,
        'O' => 79,
        'P' => 80,
        'Q' => 81,
        'R' => 82,
        'S' => 83,
        'T' => 84,
        'U' => 85,
        'V' => 86,
        'W' => 87,
        'X' => 88,
        'Y' => 89,
        'Z' => 90,
        '[' => 91,
        '\' => 92,
        ']' => 93,
        '^' => 94,
        '_' => 95,
        '`' => 96,
        'a' => 97,
        'b' => 98,
        'c' => 99,
        'd' => 100,
        'e' => 101,
        'f' => 102,
        'g' => 103,
        'h' => 104,
        'i' => 105,
        'j' => 106,
        'k' => 107,
        'l' => 108,
        'm' => 109,
        'n' => 110,
        'o' => 111,
        'p' => 112,
        'q' => 113,
        'r' => 114,
        's' => 115,
        't' => 116,
        'u' => 117,
        'v' => 118,
        'w' => 119,
        'x' => 120,
        'y' => 121,
        'z' => 122,
        '{' => 123,
        '|' => 124,
        '}' => 125,
        '~' => 126
    }

    Murmur3Hash<public> := class:
        var H : int = 2166136261

        Init<public>(Seed : string)<transacts><decides>:void=
            _h := UInt32[2166136261]
            set H = _h

            for (I := 0..Seed.Length - 1):
                C := CharCodes[Seed[I]]

                var K : int = IMul[C, 3432918353]

                _k := OR[LeftShift[K, 15], RightShift[UInt32[K], 17]]
                set K = _k

                _h1 := XOR[H, IMul[K, 461845907]]
                set H = _h1

                _h2 := OR[LeftShift[H, 13], RightShift[UInt32[H], 19]]
                set H = _h2

                _h3 := Int32[IMul[H, 5] + 3864292196]
                set H = _h3

            _hf := XOR[H, Seed.Length]
            set H = _hf

        Gen<public>()<transacts><decides>:int=

            _h := XOR[H, RightShift[UInt32[H], 16]]
            set H = _h

            _h1 := IMul[H, 2246822507]
            set H = _h1
            
            _h2 := XOR[H, RightShift[UInt32[H], 13]]
            set H = _h2

            _h3 := IMul[H, 3266489909]
            set H = _h3
            
            _hf := XOR[H, RightShift[UInt32[H], 16]]
            set H = _hf

            return UInt32[H]

    SFC32<public> := class:
        var A : int = 0x9E3779B9 # phi
        var B : int = 0x243F6A88 # pi
        var C : int = 0xB7E15162 # e
        var D : int = 0

        Init<public>(Seed : string)<transacts><decides>:int=
            Murmur3HashInstance := Murmur3Hash{}
            Murmur3HashInstance.Init[Seed]

            _a := Murmur3HashInstance.Gen[]
            set A = _a

            _b := Murmur3HashInstance.Gen[]
            set B = _b

            _c := Murmur3HashInstance.Gen[]
            set C = _c

            _d := Murmur3HashInstance.Gen[]
            set D = _d

        Gen<public>()<transacts><decides>:int=
            
            _a := UInt32[A]
            set A = _a

            _b := UInt32[B]
            set B = _b

            _c := UInt32[C]
            set C = _c

            _d := UInt32[D]
            set D = _d

            var T : int = UInt32[UInt32[A + B] + D]

            _a1 := XOR[B, RightShift[B, 9]]
            set A = _a1

            _b1 := XOR[C, LeftShift[C, 11]]
            set B = _b1

            _c1 := OR[LeftShift[C, 21], RightShift[C, 11]]
            set C = _c1

            _c2 := UInt32[C + T]
            set C = _c2

            _d1 := UInt32[D + 1]
            set D = _d1

            return UInt32[T]

        GetRandomFloat<public>(Minimum : float, Maximum : float)<transacts><decides>:float=
            Random := (1.0 * Gen[]) / 4294967296.0

            return Random * (Maximum - Minimum) + Minimum

        GetRandomInt<public>(Minimum : int, Maximum : int)<transacts><decides>:int=
            return Floor[GetRandomFloat[1.0 * Minimum, 1.0 * Maximum]]