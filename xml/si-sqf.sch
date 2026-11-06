<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    
    <pattern id="check-ids-and-refs">
        <let name="tf2RefIds"
            value="doc('metaInfo/cbml-si.xml')//@xml:id => distinct-values()"/>
        
        <rule context="@who | @characters | @ref">
            <let name="tokens" value="tokenize(normalize-space(.), '\s+')"/>
            
            <let name="badTokens"
                value="$tokens[not(starts-with(., '#') and substring-after(., '#') = $tf2RefIds)]"/>
            
            <assert test="empty($badTokens)" sqf:fix="pick-tf2-id">
                In <value-of select="current() ! name()"/>, these value(s) don't match an @xml:id in the cbml-si.xml:
                <value-of select="string-join($badTokens, ', ')"/>.
                Each value must be a # followed by a defined @xml:id.
                <!-- ebb: <value-of> lets us see something via XPath in the actual Schematron validation message!
                    string-join() is an XPath function that "glues" values together with a punctuation mark / separator of your choice. Here we're separating
                each "bad" token we find in an attribute value with a comma and space. -->
            </assert>
            
            <sqf:fix id="pick-tf2-id"
                use-for-each="
                for $b in $badTokens return
                let $stem := lower-case(substring(replace($b, '^#', ''), 1, 3)),
                $near := $tf2RefIds[contains(lower-case(.), $stem)]
                return
                for $c in (if (exists($near)) then $near else $tf2RefIds)
                return concat($b, ' ', $c)">
                <sqf:description>
                    <sqf:title>Replace "<value-of select="tokenize($sqf:current, ' ')[1]"/>"
                        with "#<value-of select="tokenize($sqf:current, ' ')[2]"/>"</sqf:title>
                </sqf:description>
                
                <!-- This part does the Quick Fix work: you rewrite the whole attribute, swapping only the bad token
                     and leaving any good tokens alone. -->
                <sqf:replace match="." node-type="attribute" target="{name()}"
                    select="string-join(
                    for $t in tokenize(normalize-space(.), '\s+')
                    return if ($t = tokenize($sqf:current, ' ')[1])
                    then concat('#', tokenize($sqf:current, ' ')[2])
                    else $t,
                    ' ')"/>
            </sqf:fix>
        </rule>
    </pattern>
</schema>