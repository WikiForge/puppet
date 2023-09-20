-- JobQueue additional metric collector
-- Author: John Lewis, Miraheze

local result = {}
local queues = { 'l-unclaimed', 'z-abandoned' }

-- Below is a list of jobs we want to monitor specifically
local jobs = {
	'*',
	'AssembleUploadChunks',
	'CentralAuthCreateLocalAccountJob',
	'CentralAuthUnattachUserJob',
	'ChangeDeletionNotification',
	'ChangeNotification',
	'ChangeVisibilityNotification',
	'CleanTermsIfUnused',
	'CreateWikiJob',
	'DataDumpGenerateJob',
	'DeleteJob',
	'DeleteTranslatableBundleJob',
	'DispatchChangeDeletionNotification',
	'DispatchChangeVisibilityNotification',
	'DispatchChanges',
	'EchoNotificationDeleteJob',
	'EchoNotificationJob',
	'EchoPushNotificationRequest',
	'EntityChangeNotification',
	'GlobalNewFilesDeleteJob',
	'GlobalNewFilesInsertJob',
	'GlobalNewFilesMoveJob',
	'GlobalUserPageLocalJobSubmitJob',
	'InitImageDataJob',
	'LocalGlobalUserPageCacheUpdateJob',
	'LocalPageMoveJob',
	'LocalRenameUserJob',
	'LoginNotifyChecks',
	'MDCreatePage',
	'MDDeletePage',
	'MWScriptJob',
	'MassMessageJob',
	'MassMessageServerSideJob',
	'MassMessageSubmitJob',
	'MessageGroupStatesUpdaterJob',
	'MessageGroupStatsRebuildJob',
	'MessageIndexRebuildJob',
	'MessageUpdateJob',
	'MoveTranslatableBundleJob',
	'NamespaceMigrationJob',
	'PageProperties',
	'PublishStashedFile',
	'PurgeEntityData',
	'RecordLintJob',
	'RemovePIIJob',
	'RenderTranslationPageJob',
	'RequestWikiAIJob',
	'SetContainersAccessJob',
	'SMW\\ChangePropagationClassUpdateJob',
	'SMW\\ChangePropagationDispatchJob',
	'SMW\\ChangePropagationUpdateJob',
	'SMW\\EntityIdDisposerJob',
	'SMW\\FulltextSearchTableRebuildJob',
	'SMW\\FulltextSearchTableUpdateJob',
	'SMW\\PropertyStatisticsRebuildJob',
	'SMW\\RefreshJob',
	'SMW\\UpdateDispatcherJob',
	'SMW\\UpdateJob',
	'SMWRefreshJob',
	'SMWUpdateJob',
	'TTMServerMessageUpdateJob',
	'ThumbnailRender',
	'TranslatableBundleDeleteJob',
	'TranslatableBundleMoveJob',
	'TranslateRenderJob',
	'TranslateSandboxEmailJob',
	'TranslationNotificationsEmailJob',
	'TranslationNotificationsSubmitJob',
	'TranslationsUpdateJob',
	'UpdateMessageBundle',
	'UpdateRepoOnDelete',
	'UpdateRepoOnMove',
	'UpdateTranslatablePageJob',
	'UpdateTranslatorActivity',
	'activityUpdateJob',
	'cargoPopulateTable',
	'categoryMembershipChange',
	'cdnPurge',
	'clearUserWatchlist',
	'clearWatchlistNotifications',
	'compileArticleMetadata',
	'constraintsRunCheck',
	'constraintsTableUpdate',
	'crosswikiSuppressUser',
	'deleteLinks',
	'deletePage',
	'dtImport',
	'edReparse',
	'enotifNotify',
	'enqueue',
	'fixDoubleRedirect',
	'flaggedrevs_CacheUpdate',
	'globalUsageCachePurge',
	'htmlCacheUpdate',
	'menteeOverviewUpdateDataForMentor',
	'newUserMessageJob',
	'newcomerTasksCacheRefreshJob',
	'null',
	'pageFormsCreatePage',
	'pageSchemasCreatePage',
	'reassignMenteesJob',
	'recentChangesUpdate',
	'refreshLinks',
	'refreshLinksDynamic',
	'refreshLinksPrioritized',
	'renameUser',
	'revertedTagUpdate',
	'sendMail',
	'setUserMentorDatabaseJob',
	'smw.changePropagationClassUpdate',
	'smw.changePropagationDispatch',
	'smw.changePropagationUpdate',
	'smw.deferredConstraintCheckUpdateJob',
	'smw.elasticFileIngest',
	'smw.elasticIndexerRecovery',
	'smw.entityIdDisposer',
	'smw.fulltextSearchTableRebuild',
	'smw.fulltextSearchTableUpdate',
	'smw.parserCachePurgeJob',
	'smw.propertyStatisticsRebuild',
	'smw.refresh',
	'smw.update',
	'smw.updateDispatcher',
	'updateBetaFeaturesUserCounts',
	'userEditCountInit',
	'userGroupExpiry',
	'userOptionsUpdate',
	'watchlistExpiry',
	'webVideoTranscode',
	'webVideoTranscodePrioritized',
	'wikibase-InjectRCRecords',
	'wikibase-addUsagesForPage'
}

for _,job in ipairs(jobs) do
	for _,queue in ipairs(queues) do
		local lsum = 0
		local lkeys = redis.call( 'KEYS', '*:jobqueue:' .. job .. ':' .. queue )
		for _,lkey in ipairs(lkeys) do
			if queue ~= 'l-unclaimed' then
				lsum = lsum + tonumber(redis.call('ZCARD', lkey))
			else
				lsum = lsum + tonumber(redis.call('LLEN', lkey))
			end
		end
		table.insert(result, job .. '-' .. queue )
		table.insert(result, tostring(lsum) )
	end
end

return result
