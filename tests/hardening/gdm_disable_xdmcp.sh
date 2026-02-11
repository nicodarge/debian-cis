# shellcheck shell=bash
# run-shellcheck
test_audit() {
    describe Installing GDM
    DEBIAN_FRONTEND=noninteractive apt-get install -y gdm3 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || true

    describe Tests purposely failing - enabling XDMCP
    # Add XDMCP enable to config
    if [ -f /etc/gdm3/custom.conf ]; then
        echo -e "\n[xdmcp]\nEnable=true" >>/etc/gdm3/custom.conf
    elif [ -f /etc/gdm3/daemon.conf ]; then
        echo -e "\n[xdmcp]\nEnable=true" >>/etc/gdm3/daemon.conf
    fi
    register_test retvalshouldbe 1
    register_test contain "XDMCP is enabled"
    # shellcheck disable=2154
    run noncompliant "${CIS_CHECKS_DIR}/${script}.sh" --audit-all

    describe Correcting situation
    sed -i 's/audit/enabled/' "${CIS_CONF_DIR}/conf.d/${script}.cfg"
    "${CIS_CHECKS_DIR}/${script}.sh" --apply || true

    describe Checking resolved state
    register_test retvalshouldbe 0
    register_test contain "not enabled"
    # shellcheck disable=2154
    run resolved "${CIS_CHECKS_DIR}/${script}.sh" --audit-all

    describe Cleanup
    # Restore original config files
    if [ -f /etc/gdm3/custom.conf ]; then
        sed -i '/^\[xdmcp\]/,/^Enable=true/d' /etc/gdm3/custom.conf
        sed -i '/#Enable=true/d' /etc/gdm3/custom.conf
    fi
    if [ -f /etc/gdm3/daemon.conf ]; then
        sed -i '/^\[xdmcp\]/,/^Enable=true/d' /etc/gdm3/daemon.conf
        sed -i '/#Enable=true/d' /etc/gdm3/daemon.conf
    fi

    # Remove package and dependencies
    apt-get remove -y gdm3 || true
    apt-get autoremove -y || true

}
