<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- don't pass text thru -->
<xsl:template match="text()|@*">
</xsl:template>

<!-- title of the article -->
<xsl:template match="//Article/ArticleInfo/ArticleTitle">
	<h1> <xsl:value-of select="."/> </h1>
</xsl:template>	

<!-- authors -->
<!-- <xsl:template match="//AuthorName">
	<b><xsl:value-of select="./GivenName"/></b> &nbsp; <b><xsl:value-of select="./FamilyName"/></b>,
</xsl:template> -->

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



<!-- headings (using h2 for all) -->
<xsl:template match="//Article/Body//Heading">
	<h2> <xsl:apply-templates/> </h2>
</xsl:template>	

<!-- abstract -->
<xsl:template match="//ArticleHeader/Abstract">
	<div class="abstract">
		<xsl:value-of select="./Para"/>
	</div>
</xsl:template>

<!-- keywords -->
<!-- <xsl:template match="//ArticleHeader/KeywordGroup[@Language='En']">
	<div class="keywords">
		Keywords: 
		<xsl:for-each select="./Keyword">
			<a href="/?search_terms=">
				<xsl:value-of select="."/>
			</a>
    </xsl:for-each>		
	</div>
</xsl:template> -->


<!-- paragraphs -->
<xsl:template match="//Article/Body//Para">
	<p> <xsl:apply-templates/> </p>
</xsl:template>	

<!-- print normal text in the body -->
<xsl:template match="//Article/Body//text()">
	<xsl:value-of select="."/>
</xsl:template>


<!-- ordered list -->
<xsl:template match="//Article/Body//OrderedList">
	<ol> <xsl:apply-templates/> </ol>
</xsl:template>

<xsl:template match="//Article/Body//OrderedList/ListItem">
	<li value="{./ItemNumber/text()}"> <xsl:apply-templates select="./ItemContent"/> </li>
</xsl:template>

<!-- <ListItem>
   <ItemNumber>(1)</ItemNumber>
   <ItemContent>
      <Para>How much can authors inflate their <Emphasis Type="Italic">h</Emphasis>-index through strategic self-citations?</Para>
   </ItemContent>
</ListItem> -->


<!-- citations -->
<!-- <CitationRef CitationID="CR10">10</CitationRef> -->
<xsl:template match="//Article/Body//CitationRef">
	<a href="#{./@CitationID}" class="citation_reference"><xsl:value-of select="."/></a>
</xsl:template>

<!-- tables -->
<xsl:template match="//Article/Body//Table">
	<table>
		<xsl:for-each select=".//row">
      <tr>
				<xsl:for-each select="./entry">
					<td>
						<xsl:apply-templates/>
					</td>
        </xsl:for-each>
      </tr>
    </xsl:for-each>
	</table>
</xsl:template>

<!-- DefinitionList -->
<xsl:template match="//Article/Body//DefinitionList">
	<table class="definition_list">
		<xsl:for-each select=".//DefinitionListEntry">
      <tr>
					<td>
						<xsl:apply-templates select="./Term"/>
					</td>
					<td>
						<xsl:apply-templates select="./Description"/>
					</td>					
      </tr>
    </xsl:for-each>
	</table>
</xsl:template>


<!-- TeX formulas -->
<!-- <EquationSource Format="TEX">
	$$\label{eq:w} \forall n\geq 1:\: W_{\theta} (n+1)=\max\big\{W_\theta (n)+D_\theta ( n+1 ) ,0\big\}, $$
</EquationSource> 
<EquationSource Format="TEX">
	$\{\Delta_\theta^- ( n,k ): n\geq 1\}$
</EquationSource> -->

<!-- pass through Equations unchanged => MathJax will do the display in the browser -->
<xsl:template match="//EquationSource">
	<xsl:value-of select="."/>
</xsl:template>	

<!-- replace figures with their corresponding files -->
<!-- <Figure Category="Standard" Float="Yes" ID="Fig2"> -->
<!-- <xsl:value-of select="//Image[APPId/text()='{@ID}']/@Id"/> -->
<!-- <xsl:template match="//Article/Body//Figure">
	<img id="{@ID}"></img>
</xsl:template> -->
<xsl:template match="//Figure">
	<!-- do nothing (which effectively removes this figure from the display) -->
</xsl:template>



<!-- NOT WORKING: create italics -->
<!-- <Emphasis Type="Italic">Y</Emphasis> -->
<xsl:template match="//Article/Body//Emphasis[@Type='Italic']">
	<em><span class="entity"> <xsl:apply-templates/> </span></em>
</xsl:template> 

<!-- <Subscript>1</Subscript> -->
<xsl:template match="//Article/Body//Subscript">
	<sub> <xsl:apply-templates/> </sub>
</xsl:template>


<!-- big - outer wrapper -->
<xsl:template match="//Bibliography">
	<div class='bibliography'> <xsl:apply-templates/> </div>
</xsl:template>

<!-- bib - heading -->
<xsl:template match="//Bibliography//Heading">
	<h2> <xsl:value-of select="."/> </h2>
</xsl:template>

<!-- bib - Citation -->
<xsl:template match="//Bibliography//Citation">
	<p> 
		<a name="{@ID}"> 
			<span class='citation_number'><xsl:value-of select="./CitationNumber"/></span> 
		</a>
		<xsl:value-of select=".//ArticleTitle"/>
		<xsl:value-of select=".//JournalTitle"/>	
		<xsl:value-of select="./BibUnstructured"/>
	</p> 
</xsl:template>


</xsl:stylesheet>