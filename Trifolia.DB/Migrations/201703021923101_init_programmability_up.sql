/****** Object:  UserDefinedTableType [dbo].[CategoryList]    Script Date: 2/10/2017 11:35:24 AM ******/
CREATE TYPE [dbo].[CategoryList] AS TABLE(
	[category] [nvarchar](255) NULL
)
GO
/****** Object:  UserDefinedFunction [dbo].[GetConstraintCategory]    Script Date: 2/10/2017 11:35:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[GetConstraintCategory] (@templateConstraintId INT)
RETURNS NVARCHAR(255)
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @constraintId INT
	DECLARE @category NVARCHAR(255)

	SET @constraintId = @templateConstraintId

	WHILE (@constraintId IS NOT NULL)
	BEGIN
		SET @category = (SELECT category FROM template_constraint WHERE id = @constraintId)

		IF (@category IS NOT NULL AND @category != '')
		BEGIN
			RETURN @category
		END

		SET @constraintId = (SELECT parentConstraintId FROM template_constraint WHERE id = @constraintId)	
	END

	RETURN ''
END;
GO
/****** Object:  UserDefinedFunction [dbo].[GetNextConformanceNumber]    Script Date: 2/10/2017 11:35:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[GetNextConformanceNumber] (
  @templateId INT)
RETURNS INT
BEGIN
  DECLARE @retValue INT
  DECLARE @implementationGuideId INT

  SET @implementationGuideId = (SELECT owningImplementationGuideId FROM template WHERE id = @templateId)

  IF (@implementationGuideId IS NULL)
  BEGIN
	  SET @retValue = (
		  SELECT ISNULL(MAX(tc.[number]), 0) + 1 FROM template t
			JOIN template_constraint tc ON tc.templateId = t.id
		  WHERE t.id = @templateId)
  END
  ELSE
  BEGIN
	  SET @retValue = (
		  SELECT ISNULL(MAX(tc.[number]), 0) + 1 FROM template t
			JOIN template_constraint tc ON tc.templateId = t.id
		  WHERE t.owningImplementationGuideId = @implementationGuideId)
  END

  RETURN @retValue
END

GO
/****** Object:  StoredProcedure [dbo].[GetImplementationGuideTemplates]    Script Date: 2/10/2017 11:35:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[GetImplementationGuideTemplates]
	@implementationGuideId INT,
	@inferred BIT,
	@parentTemplateId INT = NULL,
	@categories AS CategoryList READONLY
AS
BEGIN
	DECLARE @currentImplementationGuideId INT = @implementationGuideId, @relationshipCount INT, @retiredStatusId INT
	DECLARE @False BIT = 0, @True BIT = 1
	DECLARE @categoryCount INT

	SET @categoryCount = (SELECT COUNT(*) FROM @categories)

	CREATE TABLE #implementationGuides (id INT, [version] INT)
	CREATE TABLE #templates (id INT)
	CREATE TABLE #relationships (id INT)

	SEt @retiredStatusId = (SELECT id FROM publish_status WHERE [status] = 'Retired')

	WHILE (@currentImplementationGuideId IS NOT NULL)
	BEGIN
		INSERT INTO #implementationGuides (id, [version])
		SELECT @currentImplementationGuideId, [version] FROM implementationguide WHERE id = @currentImplementationGuideId

		SET @currentImplementationGuideId = (SELECT previousVersionImplementationGuideId FROM implementationguide WHERE id = @currentImplementationGuideId)
	END

	-- Loop through the IG versions from beginning to end adding/removing templates as appropriate
	IF (@parentTemplateId IS NULL)
	BEGIN
		DECLARE ig_cursor CURSOR
			FOR SELECT id FROM #implementationGuides ORDER BY [version]
		OPEN ig_cursor
		FETCH NEXT FROM ig_cursor INTO @currentImplementationGuideId;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			DELETE FROM #templates
			WHERE id in (SELECT previousVersionTemplateId FROM template WHERE owningImplementationGuideId = @currentImplementationGuideId)

			INSERT INTO #templates (id)
			SELECT id FROM template WHERE owningImplementationGuideId = @currentImplementationGuideId

			FETCH NEXT FROM ig_cursor INTO @currentImplementationGuideId;
		END

		CLOSE ig_cursor;
		DEALLOCATE ig_cursor;
	END
	ELSE
	BEGIN
		INSERT INTO #templates
		SELECT @parentTemplateId
	END

	-- Remove any retired templates that aren't part of this version of the IG
	DELETE FROM #templates WHERE id IN (SELECT id FROM template WHERE owningImplementationGuideId != @implementationGuideId AND statusId = @retiredStatusId)

	insert_relationships:

	INSERT INTO #relationships (id)
	-- Contained templates
	SELECT tc.containedTemplateId AS id
	FROM template_constraint tc
		JOIN #templates tt ON tt.id = tc.templateId
	WHERE
		tc.containedTemplateId IS NOT NULL AND
		tc.containedTemplateId NOT IN (SELECT id FROM #templates) AND
		-- Either not filtering by categories, constraint's category is not set, or the category matches one of the specified categories
		(@categoryCount = 0 OR dbo.GetConstraintCategory(tc.id) = '' OR dbo.GetConstraintCategory(tc.id) IN (SELECT category FROM @categories))

	UNION ALL

	-- Implied templates
	SELECT t.impliedTemplateId
	FROM template t
		JOIN #templates tt ON tt.id = t.id
	WHERE
		t.impliedTemplateId IS NOT NULL AND
		t.impliedTemplateId NOT IN (SELECT id FROM #templates)

	IF (@inferred = 1)
	BEGIN
		INSERT INTO #templates
		SELECT id
		FROM #relationships
		SET @relationshipCount = @@ROWCOUNT
	END
	ELSE
	BEGIN
		INSERT INTO #templates
		SELECT #relationships.id
		FROM #relationships
			JOIN template t ON #relationships.id = t.id
			JOIN #implementationGuides ON t.owningImplementationGuideId = #implementationGuides.id
		SET @relationshipCount = @@ROWCOUNT
	END

	DELETE FROM #relationships

	IF (@relationshipCount > 0)
	BEGIN
		GOTO insert_relationships
	END

	SELECT DISTINCT id FROM #templates

	DROP TABLE #relationships
	DROP TABLE #templates
	DROP TABLE #implementationGuides
END

GO
/****** Object:  StoredProcedure [dbo].[SearchTemplates]    Script Date: 2/10/2017 11:35:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[SearchTemplates]
	@userId INT = NULL,
	@filterImplementationGuideId INT = NULL,
	@filterName NVARCHAR(255) = NULL,
	@filterIdentifier NVARCHAR(255) = NULL,
	@filterTemplateTypeId INT = NULL,
	@filterOrganizationId INT = NULL,
	@filterContextType NVARCHAR(255) = NULL,
	@queryText NVARCHAR(255) = NULL
AS
BEGIN
	IF (@filterName = '') SET @filterName = NULL
	IF (@filterIdentifier = '') SET @filterIdentifier = NULL
	IF (@filterContextType = '') SET @filterContextType = NULL
	IF (@queryText = '') SET @queryText = NULL
	
	IF (@queryText IS NOT NULL) SET @queryText = '%' + @queryText + '%'

	DECLARE @userIsAdmin BIT = 0

	IF (@userId IS NOT NULL)
		SET @userIsAdmin = 
			CASE WHEN (SELECT COUNT(*) FROM user_role ur JOIN [role] r ON r.id = ur.roleId WHERE ur.userId = @userId AND isAdmin = 1) > 0 THEN 1
			ELSE 0 END

	CREATE TABLE #templateIds (id INT)

	-- Filter by implementation guide
	IF (@filterImplementationGuideId IS NOT NULL)
	BEGIN
		CREATE TABLE #implementationGuideTemplates (id INT)

		INSERT INTO #implementationGuideTemplates (id)
		EXEC GetImplementationGuideTemplates @implementationGuideId = @filterImplementationGuideId, @inferred = 1
		
		INSERT INTO #templateIds
		SELECT id FROM #implementationGuideTemplates
	END
	ELSE
	BEGIN
		INSERT INTO #templateIds (id)
		SELECT id FROM template
	END

	IF (@queryText IS NOT NULL OR @queryText != '')
	BEGIN
		CREATE TABLE #queryTextTemplates (id INT)

		INSERT INTO #queryTextTemplates (id)
		SELECT t.id
		FROM template t
			JOIN templatetype tt ON tt.id = t.templateTypeId
			JOIN implementationguide ig ON ig.id = t.owningImplementationGuideId
		WHERE
			t.name LIKE @queryText OR 
			t.oid LIKE @queryText OR
			tt.name LIKE @queryText OR
			ig.name LIKE @queryText OR
			EXISTS (SELECT * FROM template_constraint WHERE CONCAT(CAST(t.owningImplementationGuideId AS NVARCHAR), '-', CAST(number AS NVARCHAR)) LIKE @queryText AND template_constraint.templateId = t.id)

		DELETE FROM #templateIds
		WHERE id NOT IN (SELECT id FROM #queryTextTemplates)
	END

	IF (@userId IS NOT NULL AND @userIsAdmin = 0)
	BEGIN
		DELETE FROM #templateIds
		WHERE id NOT IN (SELECT templateId FROM v_templatePermissions WHERE userId = @userId AND permission = 'View')
	END
	
	SELECT t.id
	FROM v_templateList t
		JOIN #templateIds tid ON tid.id = t.id
	WHERE
		CHARINDEX(CASE WHEN @filterName IS NOT NULL THEN @filterName ELSE t.name END, t.name) > 0
		AND CHARINDEX(CASE WHEN @filterIdentifier IS NOT NULL THEN @filterIdentifier ELSE t.oid END, t.oid) > 0
		AND CHARINDEX(CASE WHEN @filterContextType IS NOT NULL THEN @filterContextType ELSE t.primaryContextType END, t.primaryContextType) > 0
		AND ISNULL(t.templateTypeId, 0) = CASE WHEN @filterTemplateTypeId IS NOT NULL THEN @filterTemplateTypeId ELSE ISNULL(t.templateTypeId, 0) END
		AND ISNULL(t.organizationId, 0) = CASE WHEN @filterOrganizationId IS NOT NULL THEN @filterOrganizationId ELSE ISNULL(t.organizationId, 0) END

	DROP TABLE #templateIds
END

GO
/****** Object:  StoredProcedure [dbo].[SearchValueSet]    Script Date: 2/10/2017 11:35:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[SearchValueSet]
	@userId INT = NULL,
	@searchText VARCHAR(255) = '',
	@count INT = 20,
	@page INT = 1,
	@orderProperty VARCHAR(128) = 'Name',
	@orderDesc BIT = 0
AS
BEGIN
	DECLARE @searchTextAny VARCHAR(512)
	SET @searchTextAny = CONCAT('%', @searchText, '%')

	DECLARE @offset INT
	SET @offset = (@page - 1) * @count

	DECLARE @totalItems INT

	SELECT 
		ig.id as implementationGuideId,
		CASE WHEN igp.permission IS NOT NULL THEN 1 ELSE 0 END AS canEditImplementationGuide
	INTO #publishedImplementationGuides
	FROM implementationguide ig
		JOIN publish_status ps on ps.id = ig.publishStatusId
		LEFT JOIN v_implementationGuidePermissions igp on igp.implementationGuideId = ig.id AND igp.userId = @userId AND igp.permission = 'Edit'
	WHERE
		ps.[status] = 'Published'

	SELECT DISTINCT
		vs.id as valueSetId,
		pig.canEditImplementationGuide as canEdit
	INTO #publishedValueSets
	FROM valueset vs
		JOIN template_constraint tc on tc.valueSetId = vs.id
		JOIN template t on t.id = tc.templateId
		JOIN #publishedImplementationGuides pig on pig.implementationGuideId = t.owningImplementationGuideId

	CREATE TABLE #valuesets (
		id INT, 
		name VARCHAR(255), 
		oid VARCHAR(255), 
		code VARCHAR(255), 
		[description] NVARCHAR(max), 
		intensional BIT NULL, 
		intensionalDefinition NVARCHAR(max), 
		source NVARCHAR(1024), 
		isComplete BIT)

	INSERT INTO #valuesets
	SELECT DISTINCT
		vs.id,
		vs.name,
		vs.oid,
		vs.code,
		vs.[description],
		vs.intensional,
		vs.intensionalDefinition,
		vs.source,
		CAST(CASE 
			WHEN vs.isIncomplete = 0 THEN 1
			ELSE 0
		END AS BIT) AS isComplete
	FROM valueset vs
	WHERE
		vs.code LIKE @searchTextAny
		OR vs.name LIKE @searchTextAny
		OR vs.oid LIKE @searchTextAny
		OR ISNULL(vs.description, '') LIKE @searchTextAny
		OR ISNULL(vs.source, '') LIKE @searchTextAny

	SET @totalItems = (SELECT COUNT(*) FROM #valuesets)

	SELECT
		@totalItems as totalItems,
		vs.*,
		CAST(CASE WHEN p.publishedIgCount IS NULL OR p.publishedIgCount = 0 THEN 0 ELSE 1 END AS BIT) AS hasPublishedIg,
		CAST(CASE WHEN up.uneditablePublishedIgCount IS NULL OR up.uneditablePublishedIgCount = 0 THEN 1 ELSE 0 END AS BIT) AS canEditPublishedIg
	FROM #valuesets vs
		LEFT JOIN (SELECT valueSetId, COUNT(*) as publishedIgCount FROM #publishedValueSets group by valueSetId) AS p ON p.valueSetId = vs.id
		LEFT JOIN (SELECT valueSetId, COUNT(*) as uneditablePublishedIgCount FROM #publishedValueSets WHERE canEdit = 0 GROUP BY valueSetId) as up ON up.valueSetId = vs.id
	ORDER BY 
		CASE @orderDesc WHEN 0 THEN
			CASE @orderProperty
				WHEN 'Name' THEN vs.name
				WHEN 'Oid' THEN vs.oid
				WHEN 'IsComplete' THEN CAST(vs.isComplete as VARCHAR(255))
			END
		END ASC,
		CASE @orderDesc WHEN 1 THEN
			CASE @orderProperty
				WHEN 'Name' THEN vs.name
				WHEN 'Oid' THEN vs.oid
				WHEN 'IsComplete' THEN CAST(vs.isComplete as VARCHAR(255))
			END
		END DESC
	OFFSET @offset ROWS
	FETCH NEXT @count ROWS ONLY
END
GO

/****** Object:  Trigger [dbo].[ConformanceNumberTrigger]    Script Date: 2/10/2017 11:44:58 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create trigger [dbo].[ConformanceNumberTrigger] on [dbo].[template_constraint]
after insert, update
as
   SET NoCount ON
   DECLARE @constraintId INT
   DECLARE @templateId INT

   IF EXISTS (SELECT * FROM INSERTED WHERE [number] IS NULL)
   BEGIN
     SET @constraintId = (SELECT id FROM INSERTED)
	 SET @templateId = (SELECT templateId FROM INSERTED)

     UPDATE template_constraint SET [number] = dbo.GetNextConformanceNumber(@templateId)
	 WHERE id = @constraintId
   END


GO

ALTER TABLE [dbo].[template_constraint] ENABLE TRIGGER [ConformanceNumberTrigger]
GO