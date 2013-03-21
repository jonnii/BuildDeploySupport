function Read-XmlNode() {
  param (
    [Parameter(Mandatory=$true)] [string] $filename,
    [Parameter(Mandatory=$true)] [string] $xpath
  )

  $xml = [xml](Get-Content $filename)
  $node = $xml.SelectNodes($xpath) | select -f 1
    
  if(!($node)){
    throw "could not find path $path"
  }
    
  return $node.innertext
}

function Write-XmlAttribute() {
  param (
    [Parameter(Mandatory=$true)] [string] $filename, 
    [Parameter(Mandatory=$true)] [string] $xpath, 
    [Parameter(Mandatory=$true)] [string] $name, 
    [Parameter(Mandatory=$true)] [string] $value
  )

  $xml = [xml](Get-Content $filename)
      
  $node = $xml.SelectNodes($xpath) | select -f 1
  
  if(!($node)){
    throw "could not find path $path"
  }

  $node.SetAttribute($name, $value)
  $xml.save($filename)
}