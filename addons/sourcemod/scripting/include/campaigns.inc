#if defined _campaigns_included
    #endinput
#endif
#define _campaigns_included

/**
 * Returns the current campaign display name. i.e.: Dead Center, Dark Carnival, etc.
 *
 * @param campaignName String buffer to store the campaign name.
 * @param maxLength Size of the campaignName buffer.
 *
 * @noreturn
 */
native void GetCurrentCampaign(char[] campaignName, int maxLength)

/**
 * Returns the campaign display name of a chapter.
 * i.e.: c2m1_highway -> Dark Carnival, c5m2_park -> The Parish, etc.
 *
 * @param chapterName String buffer to store the chapter name. Empty if invalid chapter.
 * @param campaignName String buffer to store the chapter's campaign name.
 * @param maxLength Size of the campaignName buffer.
 *
 * @return True if chapterName is valid, false otherwise.
 */
native bool GetCampaignOfChapter(const char[] chapterName, char[] campaignName, int maxLength)

/**
 * Returns a list of all chapters in a campaign.
 *
 * @param campaignName The campaign name.
 * @param skipFinale Whether to skip the finale chapter.
 *
 * @return An ArrayList containing all chapters in the campaign. INVALID_HANDLE if invalid campaign.
 */
native ArrayList GetCampaignChapters(const char[] campaignName, bool skipFinale = false)

/**
 * Returns the chapter after the given chapter in a campaign.
 * If the given chapter is the last chapter in the campaign,
 * an empty string is returned, unless sameCampaign is set to false.
 *
 * @param chapterName The chapter name.
 * @param nextChapterName String buffer to store the next chapter name. Empty if invalid chapter given.
 * @param maxLength Size of the nextChapterName buffer.
 * @param sameCampaign Whether to limit the next chapter to the same campaign.
 * @param skipFinale Whether to skip the finale chapter.
 *
 * @return Whether a next chapter exists (always true if sameCampaign is false).
 */
native bool GetNextChapterOf(
    const char[] chapterName,
    char[] nextChapterName,
    int maxLength,
    bool sameCampaign = true,
    bool skipFinale = false
)

/**
 * Returns the chapter before the given chapter in a campaign.
 * If the given chapter is the first chapter in the campaign,
 * an empty string is returned, unless sameCampaign is set to false.
 *
 * @param chapterName The chapter name.
 * @param prevChapterName String buffer to store the previous chapter name. Empty if invalid chapter given.
 * @param maxLength Size of the prevChapterName buffer.
 * @param sameCampaign Whether to limit the previous chapter to the same campaign.
 * @param skipFinale Whether to skip the finale chapter.
 *
 * @return Whether a previous chapter exists (always true if sameCampaign is false).
 */
native bool GetPreviousChapterOf(
    const char[] chapterName,
    char[] prevChapterName,
    int maxLength,
    bool sameCampaign = true,
    bool skipFinale = false
)

/**
 * Returns the campaign after the given campaign.
 *
 * @param campaignName The campaign name.
 * @param nextCampaignName String buffer to store the next campaign name. Empty if invalid campaign given.
 * @param maxLength Size of the nextCampaignName buffer.
 * @param officialOnly Whether to only return official campaigns.
 *
 * @return True if campaignName is valid, false otherwise.
 */
native bool GetNextCampaignOf(
    const char[] campaignName,
    char[] nextCampaignName,
    int maxLength,
    bool officialOnly = true
)

/**
 * Returns the campaign before the given campaign.
 *
 * @param campaignName The campaign name.
 * @param prevCampaignName String buffer to store the previous campaign name. Empty if invalid campaign given.
 * @param maxLength Size of the prevCampaignName buffer.
 * @param officialOnly Whether to only return official campaigns.
 *
 * @return True if campaignName is valid, false otherwise.
 */
native bool GetPreviousCampaignOf(
    const char[] campaignName,
    char[] prevCampaignName,
    int maxLength,
    bool officialOnly = true
)

/**
 * Returns whether the given campaign is official.
 * i.e.: Dead Center, Dark Carnival, etc.
 *
 * @param campaignName The campaign name.
 *
 * @return Whether the campaign is official.
 */
native bool IsOfficialCampaign(const char[] campaignName)

/**
 * Returns whether the given chapter is from an official campaign.
 * i.e.: c2m1_highway (Dark Carnival), c5m2_park (The Parish), etc.
 *
 * @param chapterName The chapter name.
 *
 * @return Whether the chapter is from an official campaign.
 */
native bool IsOfficialChapter(const char[] chapterName)

/**
 * Returns whether the given campaign exists.
 *
 * @param campaignName The campaign name.
 *
 * @return Whether the campaign exists.
 */
native bool IsValidCampaign(const char[] campaignName)

/**
 * Returns whether the given chapter exists in any campaign.
 *
 * @param chapterName The chapter name.
 *
 * @return Whether the chapter exists in any campaign.
 */
native bool IsValidChapter(const char[] chapterName)
