import groovy.transform.EqualsAndHashCode
import groovy.transform.Field
import org.apache.commons.codec.digest.DigestUtils
import org.artifactory.api.context.ContextHelper
import org.artifactory.resource.ResourceStreamHandle
import org.artifactory.storage.db.servers.service.ArtifactoryServersCommonService
import org.slf4j.Logger
import org.apache.commons.codec.binary.Base64

@Field
Bucket bucket = new Bucket(ContextHelper.get().beanForType(ArtifactoryServersCommonService), log)
bucket.loadLicensesFromEnv(System.getenv('ART_LICENSES'))

executions {
    getLicense() { params ->
        if (!checkAccess()) {
            status = 403
        } else {
            String nodeId = params['nodeId'] ? params['nodeId'][0] as String : ''
            String license = getLicenseFromBucket(nodeId)
            if (license) {
                message = license
                status = 200
            } else {
                status = 404
            }
        }
    }
    importLicense(httpMethod: 'POST') { params, ResourceStreamHandle body ->
        String licenseKey = body.inputStream.getText('UTF-8')
        bucket.loadLicense(licenseKey)
    }
}

jobs {
    clean(cron: "1/30 * * * * ?") {
        def artifactoryServersCommonService = ContextHelper.get().beanForType(ArtifactoryServersCommonService)
        new ArtifactoryInactiveServersCleaner(artifactoryServersCommonService, log).cleanInactiveArtifactoryServers()
    }
}

boolean checkAccess() {
    return security.currentUser().isAdmin()
}

String getLicenseFromBucket(String nodeId) {
    log.warn "Bucket instance : $bucket"
    // TODO : this lock is not engough, as node takes some time before it turns into 'STARTING' state
    // We should mark a license as "eventually taken"
    synchronized (bucket) {
        bucket.getLicenseKey(nodeId)
    }
}

@EqualsAndHashCode(includes = 'keyHash')
public class License {
    String keyHash
    String key
}

public class Bucket {

    Set<License> licenses = new HashSet<License>()
    private ArtifactoryServersCommonService artifactoryServersCommonService
    private Logger log

    public Bucket(ArtifactoryServersCommonService artifactoryServersCommonService, Logger log) {
        this.artifactoryServersCommonService = artifactoryServersCommonService
        this.log = log
    }

    void loadLicensesFromEnv(String licensesConcatenated) {
        String[] licenseKeys = licensesConcatenated?.split(',')
        for (String licenseKey : licenseKeys) {
            licenses << createLicense(licenseKey)
        }
        log.warn "${licenses.size()} licenses for secondary nodes loaded"
    }

    void loadLicense(String licenseKey) {
        licenses << createLicense(licenseKey)
    }

    private License createLicense(String licenseKey) {
        def hash = licenseKeyHash(licenseKey)
        log.warn "Importing license with hash : $hash"
        return new License(keyHash: hash, key: licenseKey)
    }

    public String licenseKeyHash(String licenseKey){
        String licenseKeyFormatted = formatLicenseKey(licenseKey)
        String hash = DigestUtils.sha1Hex(licenseKeyFormatted)
        log.warn "Hash calculated by plugin is ${hash}"
        return hash
    }

    private String formatLicenseKey(String licenseKey){
        licenseKey = encodeBase64StringChunked(Base64.decodeBase64(licenseKey))
        return licenseKey
    }

    private String encodeBase64StringChunked(final byte[] binaryData) {
        String tmp = new String(Base64.encodeBase64(binaryData, true),"UTF-8")
        return tmp
    }

    String getLicenseKey(String nodeId) {
        log.warn "Node $nodeId is requesting a license from the primary"
        Set<String> allLicensesHashes = licenses*.keyHash
        log.warn "All licenses : $allLicensesHashes"
        List<String> activeMemberLicensesHashes = artifactoryServersCommonService.getOtherActiveMembers().collect({ it.licenseKeyHash[0..-2] })
        log.warn "Other active member licenses : $activeMemberLicensesHashes"
        Set<String> availableLicenses = allLicensesHashes - activeMemberLicensesHashes
        log.warn "Available licenses : $availableLicenses"
        log.warn "Found ${availableLicenses.size()} available licenses"
        String license
        if (availableLicenses) {
            String availableLicenseHash = availableLicenses ? availableLicenses?.first() : null
            log.warn "HAsh of availabel license ${availableLicenseHash}"
            license = licenses.find({ it.keyHash == availableLicenseHash }).key
            log.warn "available license is $license"
        }
        return license
    }

}

public class ArtifactoryInactiveServersCleaner {

    private ArtifactoryServersCommonService artifactoryServersCommonService
    private Logger log

    ArtifactoryInactiveServersCleaner(ArtifactoryServersCommonService artifactoryServersCommonService, Logger log) {
        this.artifactoryServersCommonService = artifactoryServersCommonService
        this.log = log
    }

    List<String> cleanInactiveArtifactoryServers() {
        List<String> allMembers = artifactoryServersCommonService.getAllArtifactoryServers().collect({ it.serverId })
        List<String> activeMembersIds = artifactoryServersCommonService.getOtherActiveMembers().collect({ it.serverId })
        String primaryId = artifactoryServersCommonService.getRunningHaPrimary().serverId
        List<String> inactiveMembers = allMembers - activeMembersIds - primaryId
        log.warn "Running inactive artifactory servers cleaning task, found ${inactiveMembers.size()} inactive servers to remove"
        for (String inactiveMember : inactiveMembers) {
            artifactoryServersCommonService.removeServer(inactiveMember)
        }
        return inactiveMembers
    }

}