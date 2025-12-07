int LevenshteinDistance(const char[] str1, const char[] str2) {
    int str1Length = strlen(str1)
    int str2Length = strlen(str2)

    if (str1Length == 0) {
        return str2Length
    }

    if (str2Length == 0) {
        return str1Length
    }

    int maxLength = str1Length > str2Length ? str1Length : str2Length

    int[] prev = new int[maxLength + 1]
    int[] curr = new int[maxLength + 1]

    for (int i = 0; i <= str2Length; i++) {
        prev[i] = i
    }

    for (int i = 1; i <= str1Length; i++) {
        curr[0] = i

        for (int j = 1; j <= str2Length; j++) {
            int cost = (str1[i - 1] == str2[j - 1]) ? 0 : 1

            int deletion = prev[j] + 1
            int insertion = curr[j - 1] + 1
            int replace = prev[j - 1] + cost

            curr[j] = (deletion < insertion)
                ? ((deletion < replace) ? deletion : replace)
                : ((insertion < replace) ? insertion : replace)
        }

        for (int j = 0; j <= str2Length; j++) {
            prev[j] = curr[j]
        }
    }

    return prev[str2Length]
}

void RunLevenshteinDistanceTest(const char[] str1, const char[] str2, int expected) {
    int got = LevenshteinDistance(str1, str2)

    if (got == expected) {
        PrintToServer("[OK] \"%s\" vs \"%s\" = %d", str1, str2, got)
    } else {
        PrintToServer("[FAIL] \"%s\" vs \"%s\" => Got %d, Expected %d", str1, str2, got, expected)
    }
}