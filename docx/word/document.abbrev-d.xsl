<?xml version="1.0" encoding="UTF-8"?>
<!-- This file is based on DITA Open Toolkit project -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:opentopic="http://www.idiominc.com/opentopic"
                xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
                xmlns:ditamsg="http://dita-ot.sourceforge.net/ns/200704/ditamsg"
                xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                xmlns:x="com.elovirta.ooxml"
                version="2.0"
                exclude-result-prefixes="xs opentopic dita-ot ditamsg x">
  
  <xsl:param name="first-use-scope" select="'document'"/>
  
  <xsl:key name="abbreviated-form-keyref"
           match="*[contains(@class, ' abbrev-d/abbreviated-form ')]
                   [empty(ancestor::opentopic:map) and empty(ancestor::*[contains(@class, ' topic/title ')])]
                   [@keyref]"
           use="@keyref"/>
  
  <xsl:template match="*[contains(@class,' abbrev-d/abbreviated-form ')]" name="topic.abbreviated-form">
    <xsl:variable name="keys" select="@keyref/string()" as="xs:string?"/>
    <xsl:variable name="target" select="key('id', substring(@href, 2), $root)[contains(@class,' glossentry/glossentry ')][1]" as="element()?"/>
    <xsl:choose>
      <xsl:when test="$keys and $target">
        <xsl:call-template name="topic.term">
          <xsl:with-param name="contents">
            <xsl:variable name="use-abbreviated-form" as="xs:boolean">
              <xsl:apply-templates select="." mode="use-abbreviated-form"/>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$use-abbreviated-form">
                <xsl:apply-templates select="$target" mode="getMatchingAcronym"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="$target" mode="getMatchingSurfaceForm"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="ditamsg:no-glossentry-for-abbreviated-form">
          <xsl:with-param name="keys" select="$keys"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Should abbreviated form of glossary entry be used -->
  <xsl:template match="*" mode="use-abbreviated-form" as="xs:boolean">
    <xsl:variable name="first-use-scope-root" as="element()">
      <xsl:call-template name="get-first-use-scope-root"/>
    </xsl:variable>
    <xsl:sequence select="not(x:generate-id(.) = x:generate-id(key('abbreviated-form-keyref', @keyref, $first-use-scope-root)[1]))"/>
  </xsl:template>
  <xsl:template match="*[contains(@class,' topic/copyright ')]//*" mode="use-abbreviated-form" as="xs:boolean">
    <xsl:sequence select="false()"/>
  </xsl:template>
  <xsl:template match="*[contains(@class,' topic/title ')]//*" mode="use-abbreviated-form" as="xs:boolean">
    <xsl:sequence select="true()"/>
  </xsl:template>  

  <!-- Get element to use as root when  -->
  <xsl:template name="get-first-use-scope-root" as="element()">
    <xsl:choose>
      <xsl:when test="$first-use-scope = 'topic'">
        <xsl:sequence select="ancestor::*[contains(@class, ' topic/topic ')][1]"/>
      </xsl:when>
      <xsl:when test="$first-use-scope = 'chapter'">
        <xsl:sequence select="ancestor::*[contains(@class, ' topic/topic ')][position() = last()]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$root/*"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*" mode="getMatchingSurfaceForm">
    <xsl:variable name="glossSurfaceForm" select="*[contains(@class, ' glossentry/glossBody ')]/*[contains(@class, ' glossentry/glossSurfaceForm ')]" as="element()*"/>
    <xsl:choose>
      <xsl:when test="$glossSurfaceForm">
        <xsl:apply-templates select="$glossSurfaceForm/node()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="glossterm" select="*[contains(@class, ' glossentry/glossterm ')]"/>
        <xsl:apply-templates select="$glossterm/node()"/>
        <xsl:variable name="glossAlt" select="*[contains(@class, ' glossentry/glossBody ')]/*[contains(@class, ' glossentry/glossAlt ')]" as="element()*"/>
        <xsl:variable name="alt" select="($glossAlt/*[contains(@class, ' glossentry/glossAcronym ')] |
                                          $glossAlt/*[contains(@class, ' glossentry/glossAbbreviation ')])[1]" as="element()*"/>
        <xsl:if test="exists($alt) and not(normalize-space($glossterm) = normalize-space($alt))">
          <w:r>
            <w:t xml:space="preserve"> (</w:t>
          </w:r>
          <xsl:apply-templates select="$alt/node()"/>
          <w:r>
            <w:t xml:space="preserve">)</w:t>
          </w:r>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*" mode="getMatchingAcronym">
    <xsl:variable name="glossAlt" select="*[contains(@class, ' glossentry/glossBody ')]/*[contains(@class, ' glossentry/glossAlt ')]" as="element()*"/>
    <xsl:variable name="alt" select="($glossAlt/*[contains(@class, ' glossentry/glossAcronym ')] |
                                      $glossAlt/*[contains(@class, ' glossentry/glossAbbreviation ')] |
                                      $glossAlt/*[contains(@class, ' glossentry/glossShortForm ')])[1]" as="element()*"/>
    <xsl:choose>
      <xsl:when test="exists($alt)">
        <xsl:apply-templates select="$alt/node()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*[contains(@class, ' glossentry/glossterm ')]/node()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*" mode="getMatchingDefinition">
    <xsl:variable name="def" select="*[contains(@class, ' glossentry/glossdef ')]"/>
    <xsl:if test="exists($def)">
      <xsl:apply-templates select="$def/node()"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*" mode="ditamsg:no-glossentry-for-abbreviated-form">
    <xsl:param name="keys"/>
    <xsl:call-template name="output-message">
      <xsl:with-param name="id">DOTX060W</xsl:with-param>
      <xsl:with-param name="msgparams">%1=<xsl:value-of select="$keys"/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
