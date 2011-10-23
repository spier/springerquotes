<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- don't pass text thru -->
<xsl:template match="text()|@*">
</xsl:template>

<!-- title of the article -->
<xsl:template match="//Article/ArticleInfo/ArticleTitle">
	<h1><xsl:value-of select="."/></h1>
</xsl:template>	

<xsl:template match="//AuthorGroup">
	<div class="authors">
    <xsl:call-template name="join">
      <xsl:with-param name="valueList" select=".//AuthorName"/>
      <xsl:with-param name="separator" select="', '"/>
    </xsl:call-template>		
	</div>
</xsl:template>

<!-- template 'join' accepts valueList and separator -->
<xsl:template name="join" >
  <xsl:param name="valueList" select="''"/>
  <xsl:param name="separator" select="','"/>
  <xsl:for-each select="$valueList">
    <xsl:choose>
      <xsl:when test="position() = 1">
        <xsl:value-of select="concat(./GivenName, ' ', ./FamilyName)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($separator, ./GivenName, ' ', ./FamilyName) "/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

<!-- abstract -->
<xsl:template match="//ArticleHeader/Abstract">
	<xsl:if test="./Para">
		<div class="abstract">
			<xsl:value-of select="./Para"/>
		</div>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>